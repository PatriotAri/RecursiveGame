class_name Map

extends Node2D

## Root of every level scene. Game finds what it needs through here: where
## actors live, where the player arrives, and the round manager if any.
##
## Expected children: an entity root (Y-sorted) for actors and pickups, and
## optionally SpawnPoints/<name> markers.

@export var map_id: StringName
## Where the player and everything spawned at runtime is parented.
@export var entity_root_path:= NodePath("Y-sorted")
## Used when a door or a load names no spawn point, or names a missing one.
@export var default_spawn:= &"Default"
## Saves the game whenever the player walks in. For safe rooms between fights.
@export var autosave_on_enter:= false

func _enter_tree() -> void:
	add_to_group(&"map")

func _ready() -> void:
	# Run on its own (F6 in the editor) there's no Game to place a player, so
	# the map does it itself. Deferred so the whole map is ready first.
	if get_tree().get_first_node_in_group(&"game") == null:
		_spawn_standalone_player.call_deferred()

func get_entity_root() -> Node2D:
	var root := get_node_or_null(entity_root_path) as Node2D
	return root if root else self

func get_spawn_position(spawn_name: StringName) -> Vector2:
	var points := get_node_or_null("SpawnPoints")
	if points:
		for candidate in [spawn_name, default_spawn]:
			if candidate == &"": continue
			var marker := points.get_node_or_null(NodePath(String(candidate))) as Node2D
			if marker: return marker.global_position
		# A map with only named arrivals (FromLevel) still has somewhere to
		# put a player who names none: the first one.
		if points.get_child_count() > 0 and spawn_name == &"":
			return (points.get_child(0) as Node2D).global_position
	push_warning("Map %s: no spawn point '%s' or '%s'; using the origin." % [map_id, spawn_name, default_spawn])
	return global_position

## The world-space rectangle covered by the map's floor and walls, for
## keeping the camera from showing the void beyond them.
func get_bounds() -> Rect2:
	var bounds := Rect2()
	for layer_name in ["Ground", "Walls"]:
		var layer := get_node_or_null(layer_name) as TileMapLayer
		if layer == null or layer.tile_set == null: continue
		var cells := layer.get_used_rect()
		if cells.size == Vector2i.ZERO: continue
		var half := Vector2(layer.tile_set.tile_size) * 0.5
		var rect := Rect2(layer.to_global(layer.map_to_local(cells.position) - half), Vector2(cells.size * layer.tile_set.tile_size))
		bounds = rect if bounds.size == Vector2.ZERO else bounds.merge(rect)
	return bounds

## The first RoundManager in this map, or null for a map without rounds.
func get_round_manager() -> RoundManager:
	for node in get_tree().get_nodes_in_group(&"round_manager"):
		if is_ancestor_of(node):
			return node
	return null

func _spawn_standalone_player() -> void:
	var player := GlobalPackedScenes.player_scene.instantiate()
	get_entity_root().add_child(player)
	player.global_position = get_spawn_position(default_spawn)
	player.set_camera_limits(get_bounds())
