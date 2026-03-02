extends Node2D

var global_packed_scenes = GlobalPackedScenes

var enemy_scene = global_packed_scenes.enemy_scene

@export var spawn_count:= 1

func _ready() -> void:
	spawn_enemies()

func spawn_enemies() -> void:
	"""
	Current maximum entity count before performance 
	drop is about 400-420, will probably reduce with more
	complicated objects.
	"""
	for spawns in spawn_count:
		var new_enemy = enemy_scene.instantiate()
		#sets area for random spawns
		new_enemy.position = Vector2(randi_range(-64, -128), randi_range(0, 64))
		#instances enemy in scene
		add_child(new_enemy)
