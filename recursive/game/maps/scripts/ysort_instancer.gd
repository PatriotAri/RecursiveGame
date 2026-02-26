#temporary script to instance player and enemy into map
extends Node2D

var global_packed_scenes = GlobalPackedScenes

#preloaded scenes
var player_scene = global_packed_scenes.player_scene
var slime_spawner = global_packed_scenes.slime_spawner

func _ready() -> void:
	instance_player()
	instance_spawners()
	
func instance_player() -> void:
	var new_player = player_scene.instantiate()
	
	new_player.position = Vector2(randi_range(64, 100), randi_range(-64, 64))
	add_child(new_player)

func instance_spawners() -> void:
	#enemies will spawn relative to whatever position you set the spawner
	var spawn_point:= Vector2(-200, -40)
	var new_slime_spawner = slime_spawner.instantiate()
	
	new_slime_spawner.position = spawn_point
	add_child(new_slime_spawner)
