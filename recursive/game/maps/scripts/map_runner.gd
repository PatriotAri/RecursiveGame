class_name MapRunner

extends Node

## Owns where the player is: one of the map's levels, or the airship. Swaps
## between them behind a short fade and carries the same player node across,
## so inventory, health and round progress survive without saving. A level
## left for the airship is set aside, not freed, and picks up where it was.

@export var map: MapData
@export var fade_time:= 0.25

var player: Node2D
var level_index:= 0
var level: Level
var airship: Airship

var _fade: ColorRect
var _busy:= false

func _ready() -> void:
	_build_fade()
	if map == null or map.levels.is_empty():
		push_error("MapRunner: no map, or a map with no levels.")
		return
	player = GlobalPackedScenes.player_scene.instantiate()
	_enter_level(0)

## Whichever of the level and airship is set aside is out of the tree, so
## nothing frees it when the game scene goes — leaving to the main menu,
## respawning or quitting. This does.
func _exit_tree() -> void:
	for location in [level, airship]:
		if is_instance_valid(location) and not location.is_inside_tree():
			location.free()

func board_airship() -> void:
	if _busy or map.airship_scene == null: return
	await _transition(func() -> void:
		remove_child(level)
		if airship == null:
			airship = map.airship_scene.instantiate()
			airship.leave_requested.connect(leave_airship)
		add_child(airship)
		_place_player(airship.actors, airship.arrival.global_position))

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

func _enter_level(index: int) -> void:
	if level:
		level.queue_free()
	level_index = index
	level = map.levels[index].instantiate()
	level.airship_requested.connect(board_airship)
	level.exit_requested.connect(next_level)
	add_child(level)
	_place_player(level.actors, level.player_spawn.global_position)

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
