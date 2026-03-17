extends Node2D

var enemy_scene = GlobalPackedScenes.enemy_scene

@export var spawn_count:= 1

func _ready() -> void:
	await get_tree().process_frame
	spawn_enemies()

func spawn_enemies() -> void:
	var ysort_parent = get_parent()
	for spawns in spawn_count:
		var new_enemy = enemy_scene.instantiate()
		#sets area for random spawns
		var offset = Vector2(randi_range(-64, -128), randi_range(0, 64))
		new_enemy.position = position + offset
		#instances enemy in scene
		ysort_parent.add_child(new_enemy)
