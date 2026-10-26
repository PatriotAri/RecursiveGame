class_name LevelArea

extends Node2D

## One fightable section of a level. Owns its spawn points (EnemySpawner
## children), the door the player enters through, and the gate back to the
## safe zone. The level tells it when to spawn; it reports when every enemy
## it spawned is dead.

signal cleared

## Opens to let the player in during a round. Leave empty for the first
## area, which opens straight off the safe zone.
@export var entry_door: Door
## Shortcut back to the safe zone, open between rounds.
@export var return_gate: Door
@export var spawns: Array[SpawnEntry] = []

var _alive: Array[Node] = []
var _active:= false

## Spawns this area's enemies for its `visit`th round (0 = its first), spread
## round-robin across its spawn points.
func spawn(visit: int) -> void:
	var spawners:= _spawners()
	if spawners.is_empty():
		push_warning("%s has no EnemySpawner children." % name)
	var next:= 0
	for entry in spawns:
		for i in entry.count_for_visit(visit):
			if spawners.is_empty(): break
			var spawner: EnemySpawner = spawners[next % spawners.size()]
			next += 1
			for enemy in spawner.spawn(entry.enemy_scene, 1):
				_track(enemy)
	_active = true
	# An area with nothing to fight is cleared at once — deferred, so the
	# level finishes starting it before hearing it's done.
	if _alive.is_empty():
		_finish.call_deferred()

func _spawners() -> Array[EnemySpawner]:
	var result: Array[EnemySpawner] = []
	for child in get_children():
		if child is EnemySpawner:
			result.append(child)
	return result

func _track(enemy: Node) -> void:
	_alive.append(enemy)
	if enemy.has_signal(&"died"):
		enemy.died.connect(_on_enemy_gone.bind(enemy))
	# Backstop for anything freed without dying.
	enemy.tree_exited.connect(_on_enemy_left_tree.bind(enemy))

## Only a real deletion counts. An enemy also leaves the tree when its whole
## level is set aside for the airship, and that mustn't clear the area.
func _on_enemy_left_tree(enemy: Node) -> void:
	if enemy.is_queued_for_deletion():
		_on_enemy_gone(enemy)

func _on_enemy_gone(enemy: Node) -> void:
	if not _alive.has(enemy): return
	_alive.erase(enemy)
	if _active and _alive.is_empty():
		_finish()

func _finish() -> void:
	if not _active: return
	_active = false
	cleared.emit()
