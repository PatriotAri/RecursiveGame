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
	push_warning("Map %s: no spawn point '%s' or '%s'; using the origin." % [map_id, spawn_name, default_spawn])
	return global_position

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
