extends Node

## Save slots: three the player saves to by hand, and one the game auto-saves
## to at round boundaries. Autoloaded as Saves.
##
## Each slot is a JSON file in user://saves. Not a .tres: loading a resource
## can run scripts embedded in it, and save files are exactly the kind of
## file players download and swap. Every file carries a format version and is
## written to a temporary file first, then renamed over the old one, so a
## crash mid-write can't leave a slot half-written.
##
## Loading doesn't patch the running game. It rebuilds the game scene from
## scratch, and the map runner takes the save from take_pending() as it
## starts — so nothing from before the load can leak into it.

const DIR := "user://saves"
## Bump when the format changes, and teach _read() to upgrade older files.
const VERSION := 1
const AUTO_SLOT := 0
## Manual slots are numbered 1 to MANUAL_SLOTS.
const MANUAL_SLOTS := 3
const GAME_SCENE := "res://game/game.tscn"

var _pending: Dictionary = {}

## Whether a game is running and somewhere safe to save: on the airship, or
## in a level between rounds.
func can_save() -> bool:
	var runner := _runner()
	return runner != null and runner.can_save()

## Whether a game is in progress, which loading would replace.
func is_game_running() -> bool:
	return _runner() != null

## Writes the running game to `slot`. False if it couldn't: nowhere safe to
## save right now, or the file couldn't be written.
func save_game(slot: int) -> bool:
	if not can_save(): return false
	var runner := _runner()
	return _write(slot, {
		"version": VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"label": runner.get_save_label(),
		"game": runner.get_save_data(),
	})

## Starts the game from `slot`. False, with nothing changed, if the slot is
## empty or its file can't be used.
func load_game(slot: int) -> bool:
	var file_data := _read(slot)
	if file_data.is_empty(): return false
	_pending = file_data["game"]
	_start_game()
	return true

func new_game() -> void:
	_pending = {}
	_start_game()

## The save the game scene should start from. Handed over once, then cleared,
## so a later New Game or scene reload starts fresh.
func take_pending() -> Dictionary:
	var saved := _pending
	_pending = {}
	return saved

## The slot's "label" and "saved_at" (Unix time), or empty if it holds no
## usable save.
func slot_info(slot: int) -> Dictionary:
	var file_data := _read(slot)
	if file_data.is_empty(): return {}
	return {"label": file_data["label"], "saved_at": file_data["saved_at"]}

## The slot saved to most recently, auto or manual, or -1 if there are none.
func latest_slot() -> int:
	var latest := -1
	var latest_time := -INF
	for slot in MANUAL_SLOTS + 1:
		var info := slot_info(slot)
		if not info.is_empty() and info["saved_at"] > latest_time:
			latest = slot
			latest_time = info["saved_at"]
	return latest

func has_any_save() -> bool:
	return latest_slot() != -1

func slot_path(slot: int) -> String:
	if slot == AUTO_SLOT:
		return DIR.path_join("auto.json")
	return DIR.path_join("slot_%d.json" % slot)

func _runner() -> MapRunner:
	return get_tree().get_first_node_in_group(&"map_runner") as MapRunner

func _start_game() -> void:
	# Loading from the pause menu or the death screen: the new scene mustn't
	# start paused.
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)

func _write(slot: int, file_data: Dictionary) -> bool:
	var error := DirAccess.make_dir_recursive_absolute(DIR)
	if error != OK:
		push_warning("Saves: couldn't create %s (error %d)." % [DIR, error])
		return false
	var path := slot_path(slot)
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_warning("Saves: couldn't open %s (error %d)." % [temp, FileAccess.get_open_error()])
		return false
	var written := file.store_string(JSON.stringify(file_data, "\t"))
	file.close()
	if not written:
		push_warning("Saves: couldn't write %s." % temp)
		return false
	error = DirAccess.rename_absolute(temp, path)
	if error != OK:
		push_warning("Saves: couldn't replace %s (error %d)." % [path, error])
		return false
	return true

## The whole file, checked, or empty if it's missing, damaged, or not a save
## this version of the game can read.
func _read(slot: int) -> Dictionary:
	var path := slot_path(slot)
	# Where renaming over a file means deleting it first (Windows), a crash
	# in between leaves only the finished temporary file.
	if not FileAccess.file_exists(path):
		path += ".tmp"
		if not FileAccess.file_exists(path): return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_warning("Saves: %s is damaged (%s, line %d)." % [path, json.get_error_message(), json.get_error_line()])
		return {}
	if not _is_valid(json.data):
		push_warning("Saves: %s isn't a save this version of the game can read." % path)
		return {}
	return json.data

## Checks every field has the type its reader expects, before anything reads
## it. A hand-edited or damaged save gets turned away here rather than
## breaking the game halfway through loading. JSON numbers all come back as
## floats.
func _is_valid(file_data: Variant) -> bool:
	if not file_data is Dictionary: return false
	if not (file_data.get("version") is float and file_data["version"] == VERSION): return false
	if not (file_data.get("saved_at") is float and file_data.get("label") is String): return false
	var game: Variant = file_data.get("game")
	if not (game is Dictionary and game.get("map") is String
			and game.get("level_index") is float and game.get("on_airship") is bool):
		return false
	var level: Variant = game.get("level")
	if not (level is Dictionary and _are_numbers(level, ["round_number", "unlocked_areas", "last_area"])
			and level.get("completed") is bool and level.get("taken_pickups") is Array):
		return false
	var player: Variant = game.get("player")
	if not (player is Dictionary and _are_numbers(player, ["health", "stamina", "mana"])
			and player.get("inventory") is Dictionary and player.get("equipment") is Dictionary):
		return false
	if not _is_position(player.get("position")): return false
	# Optional: saves from before drops were kept don't have it.
	var drops: Variant = level.get("drops", [])
	if not drops is Array: return false
	for drop in drops:
		if not (drop is Dictionary and drop.get("scene") is String and drop.get("item") is String
				and drop.get("amount") is float and drop.get("parent") is String
				and _is_position(drop.get("position"))):
			return false
	for count in player["inventory"].values():
		if not count is float: return false
	for id in player["equipment"].values():
		if not id is String: return false
	for path in level["taken_pickups"]:
		if not path is String: return false
	# Optional too: saves from before spells.
	for key in ["spells", "spell_slots"]:
		var ids: Variant = player.get(key, [])
		if not ids is Array: return false
		for id in ids:
			if not id is String: return false
	for key in ["readied_spell", "stowed_weapon"]:
		if not player.get(key, "") is String: return false
	return true

func _is_position(value: Variant) -> bool:
	return value is Array and value.size() == 2 and value[0] is float and value[1] is float

func _are_numbers(section: Dictionary, keys: Array) -> bool:
	for key in keys:
		if not section.get(key) is float: return false
	return true
