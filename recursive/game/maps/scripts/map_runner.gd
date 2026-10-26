class_name MapRunner

extends Node

## Owns where the player is: one of the map's levels, or the airship. Swaps
## between them behind a short fade and carries the same player node across,
## so inventory, health and round progress survive the trip. A level left for
## the airship is set aside, not freed, and picks up where it was. Also the
## one place a save is gathered from and put back into.

@export var map: MapData
@export var fade_time:= 0.25

var player: Node2D
var level_index:= 0
var level: Level
var airship: Airship

var _fade: ColorRect
var _busy:= false

func _ready() -> void:
	add_to_group(&"map_runner")
	_build_fade()
	var saved:= Saves.take_pending()
	if not saved.is_empty():
		_use_saved_map(saved)
	if map == null or map.levels.is_empty():
		push_error("MapRunner: no map, or a map with no levels.")
		return
	player = GlobalPackedScenes.player_scene.instantiate()
	if saved.is_empty():
		_enter_level(0)
	else:
		_restore(saved)

## Whichever of the level and airship is set aside is out of the tree, so
## nothing frees it when the game scene goes — leaving to the main menu,
## respawning or quitting. This does.
func _exit_tree() -> void:
	for location in [level, airship]:
		if is_instance_valid(location) and not location.is_inside_tree():
			location.free()

## Saving is only allowed somewhere safe: on the airship, or in a level
## between rounds. Never mid-fade or with the player dead.
func can_save() -> bool:
	if _busy or player == null or player.data.is_dead: return false
	if is_on_airship(): return true
	return level != null and level.state == Level.State.BETWEEN_ROUNDS

func is_on_airship() -> bool:
	return airship != null and airship.is_inside_tree()

## Everything a save holds. Saves adds its own header around this.
func get_save_data() -> Dictionary:
	return {
		"map": map.resource_path,
		"level_index": level_index,
		"on_airship": is_on_airship(),
		"level": level.get_save_data(),
		"player": player.get_save_data(),
	}

## One line for the save slot list, e.g. "Test Map - Level 1, Round 3". Saves
## are made between rounds, so the round named is the one that comes next.
func get_save_label() -> String:
	var where:= "Airship" if is_on_airship() else "Round %d" % (level.round_number + 1)
	return "%s - Level %d, %s" % [map.display_name, level_index + 1, where]

func board_airship() -> void:
	if _busy or map.airship_scene == null: return
	await _transition(_swap_to_airship)

func leave_airship() -> void:
	if _busy: return
	await _transition(func() -> void:
		remove_child(airship)
		add_child(level)
		_place_player(level.actors, level.ramp_arrival.global_position))

func next_level() -> void:
	if _busy: return
	if level_index + 1 >= map.levels.size():
		push_warning("MapRunner: %s has no level after %d." % [map.display_name, level_index])
		return
	await _transition(func() -> void: _enter_level(level_index + 1))

func _swap_to_airship() -> void:
	remove_child(level)
	if airship == null:
		airship = map.airship_scene.instantiate()
		airship.leave_requested.connect(leave_airship)
	add_child(airship)
	_place_player(airship.actors, airship.arrival.global_position)

func _enter_level(index: int) -> void:
	if level:
		level.queue_free()
	level_index = index
	level = map.levels[index].instantiate()
	level.airship_requested.connect(board_airship)
	level.exit_requested.connect(next_level)
	# Auto-saves land on round boundaries only: just before a round, and as
	# soon as one is cleared.
	level.round_starting.connect(_auto_save.unbind(1))
	level.round_cleared.connect(_auto_save.unbind(1))
	add_child(level)
	_place_player(level.actors, level.player_spawn.global_position)

func _auto_save() -> void:
	Saves.save_game(Saves.AUTO_SLOT)

## A save names its map; use that one if it's a real map in the game.
func _use_saved_map(saved: Dictionary) -> void:
	var path:= String(saved.get("map", ""))
	if map and path == map.resource_path: return
	var saved_map: MapData = null
	# Only paths inside the game itself: a save file is player-editable.
	if path.begins_with("res://") and ResourceLoader.exists(path):
		saved_map = load(path) as MapData
	if saved_map:
		map = saved_map
	else:
		push_warning("MapRunner: the save names an unknown map '%s'." % path)

## Rebuilds the saved spot: its level, put back as it was, then the airship
## if that's where the save was made, then the player's own state.
func _restore(saved: Dictionary) -> void:
	_enter_level(clampi(int(saved.get("level_index", 0)), 0, map.levels.size() - 1))
	level.load_save_data(saved.get("level", {}))
	if saved.get("on_airship", false) and map.airship_scene:
		_swap_to_airship()
	player.load_save_data(saved.get("player", {}))

func _place_player(parent: Node, at: Vector2) -> void:
	if player.get_parent():
		player.get_parent().remove_child(player)
	parent.add_child(player)
	player.global_position = at

## Fades out, runs `swap` while the screen is black, then fades back in. The
## player is frozen meanwhile, so it can't walk off mid-fade.
func _transition(swap: Callable) -> void:
	_busy = true
	player.set_physics_process(false)
	await _fade_to(1.0)
	swap.call()
	await _fade_to(0.0)
	player.set_physics_process(true)
	_busy = false

func _fade_to(alpha: float) -> void:
	var tween:= create_tween()
	tween.tween_property(_fade, "color:a", alpha, fade_time)
	await tween.finished

func _build_fade() -> void:
	var layer:= CanvasLayer.new()
	# Above the HUD, below the pause and death screens.
	layer.layer = 5
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
