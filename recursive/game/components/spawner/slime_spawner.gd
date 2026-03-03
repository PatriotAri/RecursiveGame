extends Node2D

var enemy_scene = GlobalPackedScenes.enemy_scene

@export var spawn_count:= 1

func _ready() -> void:
	spawn_enemies()

func spawn_enemies() -> void:
	for spawns in spawn_count:
		var new_enemy = enemy_scene.instantiate()
		#sets area for random spawns
		new_enemy.position = Vector2(randi_range(-64, -128), randi_range(0, 64))
		#instances enemy in scene
		add_child(new_enemy)
