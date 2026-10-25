extends Node

## Autoloaded as SaveManager. One save slot, written as JSON so it can be read
## and fixed by hand. Saving asks Game and the player for their state;
## loading reloads the game scene and hands Game the data to rebuild from.

## Emitted after a successful save, for UI feedback.
signal saved

const SAVE_PATH := "user://save_slot_1.json"
## Bump when the format changes in a way old saves can't be read as.
const SAVE_VERSION := 1
const GAME_SCENE := "res://game/game.tscn"

const ITEMS: ItemDatabase = preload("res://game/items/item_database.tres")

## Set by load_game(), consumed by Game on its next _ready().
var _pending: Dictionary = {}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Writes the running game to the slot. Returns false (and leaves any
## previous save untouched) if anything goes wrong.
func save_game() -> bool:
	var game := get_tree().get_first_node_in_group(&"game") as Game
	if game == null or game.player == null:
		push_warning("SaveManager: nothing to save — no game running.")
		return false
	var data := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"map_id": String(game.current_map_id),
		"map_name": game.map_display_name(),
		"player": game.player.to_save_data(),
	}
	# Written beside the real save and swapped in, so a crash mid-write can't
	# leave a half-written file where the only save used to be.
	var tmp_path := SAVE_PATH + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: couldn't write %s (error %d)." % [tmp_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var err := DirAccess.rename_absolute(tmp_path, SAVE_PATH)
	if err != OK:
		push_warning("SaveManager: couldn't replace the save (error %d)." % err)
		return false
	saved.emit()
	return true

## Reads the slot and restarts the game scene from it. Works from the main
## menu, the pause menu, or the death screen.
func load_game() -> bool:
	var data := read_save()
	if data.is_empty(): return false
	_pending = data
	Menus.reset()
	get_tree().change_scene_to_file(GAME_SCENE)
	return true

## The save's contents, or {} if there's no readable save of this version.
func read_save() -> Dictionary:
	if not has_save(): return {}
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: %s isn't valid save data." % SAVE_PATH)
		return {}
	if int(parsed.get("version", 0)) != SAVE_VERSION:
		push_warning("SaveManager: save is version %s, expected %d." % [parsed.get("version"), SAVE_VERSION])
		return {}
	return parsed

## One line for a menu: where and when.
func describe_save() -> String:
	var data := read_save()
	if data.is_empty(): return ""
	return "%s — %s" % [data.get("map_name", data.get("map_id", "?")), String(data.get("saved_at", "")).replace("T", " ")]

## Hands over the data load_game() stashed, once. Game calls this on start.
func take_pending_load() -> Dictionary:
	var data := _pending
	_pending = {}
	return data

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
