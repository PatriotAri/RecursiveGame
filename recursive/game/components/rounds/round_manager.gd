class_name RoundManager

extends Node

## Runs a map's fights as numbered rounds. start_round() sends every
## spawner in the map its batch; the round ends when every enemy it spawned
## is dead. Doors and the round button listen to the signals.

signal round_started(round_number: int)
signal round_completed(round_number: int)
## Enemies still to kill this round, spawned or still queued.
signal remaining_changed(remaining: int)
## After the last round of a map with a fixed count.
signal all_rounds_completed

## 0 = endless.
@export var total_rounds:= 3
@export var start_sound: SoundEffect = preload("res://game/audio/sfx/round_start.tres")

var current_round:= 0
var active:= false

var _spawners: Array[EnemySpawner] = []
var _alive: Array[Node] = []

func _enter_tree() -> void:
	# Joined on entering the tree, before any spawner's _ready can look for us.
	add_to_group(&"round_manager")

func _ready() -> void:
	_collect_spawners()

## Claims every spawner in this map. Run again before each round, since
## whether spawners are ready before this node depends on scene order.
func _collect_spawners() -> void:
	for node in get_tree().get_nodes_in_group(&"enemy_spawner"):
		var spawner := node as EnemySpawner
		if spawner == null or _spawners.has(spawner): continue
		if owner and not owner.is_ancestor_of(spawner): continue
		spawner.managed = true
		spawner.enemy_spawned.connect(_on_enemy_spawned)
		_spawners.append(spawner)

func can_start() -> bool:
	return not active and not is_finished()

func is_finished() -> bool:
	return total_rounds > 0 and current_round >= total_rounds and not active

func start_round() -> bool:
	if not can_start(): return false
	_collect_spawners()
	current_round += 1
	active = true
	for spawner in _spawners:
		spawner.spawn_for_round(current_round)
	AudioManager.play_sfx(start_sound)
	round_started.emit(current_round)
	_check()
	return true

func remaining() -> int:
	var count := 0
	for enemy in _alive:
		if is_instance_valid(enemy) and not _is_dead(enemy):
			count += 1
	for spawner in _spawners:
		count += spawner.pending_count()
	return count

func _on_enemy_spawned(enemy: Node) -> void:
	_alive.append(enemy)
	var actor := enemy as Actor
	if actor:
		actor.died.connect(_check)
	enemy.tree_exited.connect(_check)
	_check()

func _is_dead(enemy: Node) -> bool:
	var actor := enemy as Actor
	return actor != null and actor.actor_data != null and actor.actor_data.is_dead

func _check() -> void:
	if not is_inside_tree(): return
	var left := remaining()
	remaining_changed.emit(left)
	if active and left == 0:
		active = false
		_alive.clear()
		round_completed.emit(current_round)
		if is_finished():
			all_rounds_completed.emit()
