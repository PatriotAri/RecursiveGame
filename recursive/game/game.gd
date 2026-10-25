class_name Game

extends Node

## The running game: owns the player and swaps maps underneath it. The
## player is created once and carried from map to map, so inventory, stats
## and equipment survive every door.

signal map_changed(map: Map)

@export var registry: MapRegistry
@export var starting_map:= &"test_level_01"
@export var fade_time:= 0.2

@onready var map_container: Node = $MapContainer

var current_map: Map
var current_map_id: StringName
var player: CharacterBody2D

var _fade: ColorRect
var _changing:= false

func _enter_tree() -> void:
	# In _enter_tree, not _ready: maps check for a Game while they're being
	# added, and that happens inside this node's _ready.
	add_to_group(&"game")

func _ready() -> void:
	_build_fade()
	player = GlobalPackedScenes.player_scene.instantiate()
	var save := SaveManager.take_pending_load()
	if save.is_empty():
		_load_map(starting_map, &"")
	else:
		_load_from_save(save)

## Rebuilds from save data: the saved map, then the player's state on top.
## A map that no longer exists falls back to the starting map rather than
## refusing the save outright.
func _load_from_save(save: Dictionary) -> void:
	var map_id := StringName(save.get("map_id", ""))
	if registry == null or registry.find(map_id) == null:
		push_warning("Game: saved map '%s' is gone; starting at '%s'." % [map_id, starting_map])
		map_id = starting_map
	_load_map(map_id, &"")
	player.apply_save_data(save.get("player", {}), SaveManager.ITEMS)

func map_display_name() -> String:
	var data := registry.find(current_map_id) if registry else null
	return data.display_name if data and data.display_name != "" else String(current_map_id)

## Fades out, swaps to `map_id`, places the player at `spawn_name`, fades in.
## Safe to call from inside physics callbacks (a door's body_entered).
func change_map(map_id: StringName, spawn_name: StringName = &"") -> void:
	if _changing: return
	if registry == null or registry.find(map_id) == null:
		push_error("Game: no map '%s' in the registry." % map_id)
		return
	_changing = true
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, fade_time)
	await tween.finished
	_load_map(map_id, spawn_name)
	if current_map.autosave_on_enter:
		SaveManager.save_game()
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, fade_time)
	await tween.finished
	_changing = false

func _load_map(map_id: StringName, spawn_name: StringName) -> void:
	var data := registry.find(map_id) if registry else null
	if data == null:
		push_error("Game: no map '%s' in the registry." % map_id)
		return
	var scene := load(data.scene_path) as PackedScene
	var map := scene.instantiate() as Map if scene else null
	if map == null:
		push_error("Game: '%s' isn't a scene with a Map root." % data.scene_path)
		return
	
	if current_map:
		# Out of the old map before it's freed, or the player goes with it.
		if player.get_parent():
			player.get_parent().remove_child(player)
		player.player_interaction_system.clear()
		# Removed now, freed later: queue_free alone would leave the old
		# map's enemies and round manager in their groups for the rest of
		# the frame, where the new map would find them.
		map_container.remove_child(current_map)
		current_map.queue_free()
	
	map_container.add_child(map)
	current_map = map
	current_map_id = map_id
	map.get_entity_root().add_child(player)
	player.global_position = map.get_spawn_position(spawn_name)
	player.velocity = Vector2.ZERO
	player.set_camera_limits(map.get_bounds())
	if data.music:
		AudioManager.play_music(data.music)
	map_changed.emit(map)

func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	add_child(layer)
