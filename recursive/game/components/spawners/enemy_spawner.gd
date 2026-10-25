class_name EnemySpawner

extends Marker2D

## Spawns enemies around itself. Runs on its own (once on ready, optionally
## in timed waves), or is driven round by round by a RoundManager in the
## same map, which takes it over by setting `managed`.

signal enemy_spawned(enemy: Node)

## Used when `entries` is empty.
@export var enemy_scene: PackedScene
## A weighted mix to pick from. Entries whose min_round hasn't arrived yet
## are skipped.
@export var entries: Array[SpawnEntry] = []

@export_group("Spawn Tuning")
@export var spawn_count:= 1
@export var spawn_radius:= 60.0
#minimum distance between spawned enemies
@export var spawn_separation:= 40.0
## Positions closer than this to the player are re-rolled, so nothing
## appears on top of them.
@export var min_player_distance:= 96.0
## Seconds between individual spawns in one batch. 0 spawns the whole batch
## on one frame.
@export var spawn_interval:= 0.0

@export_group("Round Tuning")
## Added to spawn_count for every round after the first.
@export var extra_per_round:= 1

@export_group("Wave Tuning")
## Spawns once by itself on ready. Ignored when a RoundManager drives it.
@export var spawn_on_ready:= true
@export var waves_on:= false
#seconds between waves
@export var wave_intervals:= 10.0
#max enemies allowed to spawn
@export var max_enemies:= 0

## Set by a RoundManager: no spawning except when it asks.
var managed:= false

var enemies_alive: Array[Node] = []
var wave_timer:= 0.0

var _queued:= 0
var _queue_timer:= 0.0
var _round:= 1
var _recent_positions: Array[Vector2] = []

func _ready() -> void:
	add_to_group(&"enemy_spawner")
	# The marker sprite is for placing spawners in the editor, not for play.
	var marker := get_node_or_null("Sprite2D") as CanvasItem
	if marker: marker.visible = false
	if enemy_scene == null and entries.is_empty():
		enemy_scene = GlobalPackedScenes.crawler_scene
	wave_timer = wave_intervals
	await get_tree().process_frame
	if spawn_on_ready and not managed and not _in_round_map():
		spawn_wave()

## True when a RoundManager in the same map will be driving this spawner,
## whether or not it has claimed it yet — ready order isn't guaranteed.
func _in_round_map() -> bool:
	for manager in get_tree().get_nodes_in_group(&"round_manager"):
		if manager.owner and manager.owner.is_ancestor_of(self):
			return true
	return false

func _process(delta:float) -> void:
	if _queued > 0:
		_queue_timer -= delta
		if _queue_timer <= 0.0:
			_queue_timer = spawn_interval
			_queued -= 1
			_spawn_one()
	
	if managed or not waves_on:
		return
	wave_timer -= delta
	if wave_timer <= 0.0:
		wave_timer = wave_intervals
		spawn_wave()

func spawn_wave() -> void:
	prune_dead()
	var count := spawn_count
	if max_enemies > 0:
		count = mini(count, max_enemies - enemies_alive.size() - _queued)
	_queue(count)

## Queues this round's batch and returns its size, so the round manager
## knows how many to wait for.
func spawn_for_round(round_number: int) -> int:
	_round = round_number
	var count := spawn_count + extra_per_round * maxi(round_number - 1, 0)
	_queue(count)
	return count

## Enemies queued but not spawned yet.
func pending_count() -> int:
	return _queued

func _queue(count: int) -> void:
	if count <= 0: return
	_recent_positions.clear()
	_queued += count
	if spawn_interval <= 0.0:
		# Whole batch now, rather than one per frame.
		while _queued > 0:
			_queued -= 1
			_spawn_one()

func _spawn_one() -> void:
	var scene := _pick_scene()
	if scene == null:
		push_warning("%s: nothing to spawn for round %d." % [name, _round])
		return
	var pos := pick_position(_recent_positions)
	_recent_positions.append(pos)
	var enemy := scene.instantiate()
	# pick_position() returns world space. Assigning it to `position`
	# treated it as a local offset — correct only while Y-sorted happens
	# to sit at the origin. global_position needs the node in the tree,
	# hence the reorder.
	get_parent().add_child(enemy)
	enemy.global_position = pos
	enemies_alive.append(enemy)
	enemy_spawned.emit(enemy)

func _pick_scene() -> PackedScene:
	var total := 0.0
	for entry in entries:
		if entry and entry.scene and entry.min_round <= _round:
			total += entry.weight
	if total <= 0.0:
		return enemy_scene
	var roll := randf() * total
	for entry in entries:
		if entry and entry.scene and entry.min_round <= _round:
			roll -= entry.weight
			if roll <= 0.0:
				return entry.scene
	return enemy_scene

func pick_position(existing: Array[Vector2]) -> Vector2:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	for attempts in 10:
		var angle:= randf() * TAU
		var dist:= randf_range(0.0, spawn_radius)
		var candidate:= _walkable(global_position + Vector2(cos(angle), sin(angle)) * dist)
		
		var too_close:= false
		for other in existing:
			if candidate.distance_to(other) < spawn_separation:
				too_close = true
				break
		if player and candidate.distance_to(player.global_position) < min_player_distance:
			too_close = true
		if not too_close:
			return candidate
	
	var angle:= randf() * TAU
	return _walkable(global_position + Vector2(cos(angle), sin(angle)) * spawn_radius)

## Snapped onto the navmesh when the level has one, so a spawn never lands
## inside a wall.
func _walkable(point: Vector2) -> Vector2:
	var map := get_world_2d().navigation_map
	# No polygon yet (the level's navmesh hasn't been baked in): leave it be.
	if NavigationServer2D.map_get_iteration_id(map) == 0 \
			or not NavigationServer2D.map_get_closest_point_owner(map, point).is_valid():
		return point
	return NavigationServer2D.map_get_closest_point(map, point)

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
