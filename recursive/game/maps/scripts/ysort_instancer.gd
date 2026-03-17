#temporary script to instance player and enemy into map
extends Node2D

var global_packed_scenes = GlobalPackedScenes
var player_scene = global_packed_scenes.player_scene

func _ready() -> void:
	instance_player()

func instance_player() -> void:
	var new_player = player_scene.instantiate()
	
	new_player.position = Vector2(randi_range(64, 100), randi_range(-64, 64))
	add_child(new_player)
