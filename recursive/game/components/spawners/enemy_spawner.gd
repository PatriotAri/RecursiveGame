class_name EnemySpawner

extends Node2D

@export var enemy_scene: PackedScene

@export var enemy_scene_transform: Vector2 = Vector2(2, 2)

@export_group("Spawn Tuning")
@export var spawn_count:= 1
@export var spawn_radius:= 60.0
#minimum distance between spawned enemies
@export var spawn_seperation:= 40.0

@export_group("Wave Tuning")
@export var waves_on:= false
#seconds between waves
@export var wave_interval:= 10.0
#max enemies allowed to spawn from spawner
@export var max_enemies:= 0

var enemies_alive: Array[Node] = []
var wave_timer:= 0.0

func _ready() -> void:
	if enemy_scene == null:
		enemy_scene = GlobalPackedScenes.enemy_scene
	await get_tree().process_frame
	spawn_wave()

func _process(delta:float) -> void:
	if not waves_on:
		set_process(false)
		return
	wave_timer -= delta
	if wave_timer <= 0.0:
		wave_timer = wave_interval
		spawn_wave()

func spawn_wave() -> void:
	prune_dead()
	
	var target_parent:= get_parent()
	var spawned:= 0
	var positions: Array[Vector2] = []
	
	for i in spawn_count:
		if max_enemies > 0 and (enemies_alive.size() + spawned) >= max_enemies:
			break
		
		var pos:= pick_position(positions)
		positions.append(pos)
		
		var enemy:= enemy_scene.instantiate()
		enemy.position = pos
		target_parent.add_child(enemy)
		enemies_alive.append(enemy)
		spawned += 1

func pick_position(existing: Array[Vector2]) -> Vector2:
	for attempts in 10:
		var angle:= randf() * TAU
		var dist:= randf_range(0.0, spawn_radius)
		var candidate:= global_position + Vector2(cos(angle), sin(angle)) * dist
		
		var too_close:= false
		for other in existing:
			if candidate.distance_to(other) < spawn_seperation:
				too_close = true
				break
		if not too_close:
			return candidate
	
	var angle:= randf() * TAU
	return global_position + Vector2(cos(angle), sin(angle)) * spawn_radius

func prune_dead() -> void:
	var still_alive: Array[Node] = []
	for enemy in enemies_alive:
		if is_instance_valid(enemy):
			still_alive.append(enemy)
	enemies_alive = still_alive

func spawn_wave_manual() -> void:
	spawn_wave()

func get_alive_count() -> int:
	prune_dead()
	return enemies_alive.size()
