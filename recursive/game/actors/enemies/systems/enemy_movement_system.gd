class_name EnemyMovementSystem

#references
var body: Enemy
var data: EnemyData

#patrol variables
var patrol_wait_time: float
var patrol_timer: float
var patrol_target:= Vector2.ZERO
var min_patrol_distance: float
#search variables
var search_timeout: float
var search_timer:= 0.0
## How far the enemy has to get before a search counts as making headway.
var search_progress_distance:= 16.0
var _search_anchor:= Vector2.ZERO
var max_attempts:= 10
var arrival_threshold:= 5.0
#pathfinding
var agent: NavigationAgent2D
## How far the target has to move before the path is worked out again.
## Re-pathing every frame for every enemy is where navigation gets expensive.
var repath_distance:= 8.0
var _last_target:= Vector2.INF
# Where avoidance says this enemy can move without walking into another one.
# Arrives through the agent's velocity_computed signal, a frame behind.
var _safe_velocity:= Vector2.ZERO
var _navigation_ready:= false
# The enemy's own intent-driven velocity. Impulses are layered onto
# body.velocity for one frame only and never stored back here.
var locomotion := Vector2.ZERO

func _init(body_ref: Enemy, data_ref: EnemyData) -> void:
	body = body_ref
	data = data_ref
	
	patrol_wait_time = body.patrol_wait_time
	patrol_timer = body.patrol_timer
	min_patrol_distance = body.min_patrol_distance
	search_timeout = body.search_timeout
	
	agent = body.navigation_agent
	if agent:
		agent.velocity_computed.connect(_on_velocity_computed)
	
	pick_patrol_target() #sets patrol point on spawn

func update(delta: float) -> void:
	data.modifiers.update(delta)

	#velocity override takes full control
	if data.modifiers.has_velocity_override():
		locomotion = data.modifiers.get_velocity_override()
		body.velocity = locomotion
		body.move_and_slide()
		return

	#reads the flag set by state machine
	if data.state_just_changed:
		_on_state_changed(data.previous_state, data.current_state)

	match data.current_state:
		EnemyData.State.PATROL:
			patrol(delta)
		EnemyData.State.CHASE:
			chase(delta)
		EnemyData.State.SEARCH:
			search(delta)
		EnemyData.State.ATTACK:
			attack(delta)
		EnemyData.State.ATTACK_COOLDOWN:
			attack_cooldown(delta)
		_:
			idle(delta)

# Single exit point for movement, so the impulse is applied once per frame
# no matter which state ran.
func _commit() -> void:
	var move:= locomotion
	if _avoiding():
		# Avoidance steers the enemy's own movement only; knockback below
		# still lands at full strength.
		agent.velocity = locomotion
		move = _safe_velocity
	body.velocity = move + data.modifiers.get_impulse_sum()
	body.move_and_slide()

func idle(delta: float) -> void:
	locomotion = locomotion.move_toward(Vector2.ZERO, data.friction * delta)
	_commit()

func patrol(delta: float) -> void:
	var dir_norm:= _direction_to(patrol_target)
	#the "arrival_threshold" tells the enemy when its within the range,
	#act like it's reached the patrol point. This prevents the enemy from 
	#jittering on the patrol point or not being able to find the patrol point all together.
	var arrived:= body.global_position.distance_to(patrol_target) < arrival_threshold
	# A point the path can't quite reach ends where the path does, instead of
	# leaving the enemy pressed against a wall forever.
	if _has_navigation() and agent.is_navigation_finished():
		arrived = true
	if arrived:
		idle(delta)
		patrol_timer += delta
		if patrol_timer >= patrol_wait_time:
			patrol_timer = 0.0
			pick_patrol_target()
	else:
		data.facing_dir = dir_norm
		var speed:= data.patrol_speed * data.modifiers.get_speed_scale()
		var target_velocity:= dir_norm * speed
		locomotion = locomotion.move_toward(target_velocity, data.acceleration * delta)
		_commit()

func pick_patrol_target() -> void:
	if not body.has_node("PatrolZone"):
		patrol_target = body.global_position
		return
		
	var zone:= body.get_node("PatrolZone")
	var shape:= zone.get_node("CollisionShape2D").shape as RectangleShape2D
	var half:= shape.size / 2.0
	
	for attempts in max_attempts:
		var candidate:= body.global_position + Vector2(
			randf_range(-half.x, half.x),
			randf_range(-half.y, half.y)
		)
		if _has_navigation():
			# Only somewhere the enemy can stand. A point inside a wall moves
			# to the nearest walkable spot.
			candidate = NavigationServer2D.map_get_closest_point(agent.get_navigation_map(), candidate)
		if body.global_position.distance_to(candidate) >= min_patrol_distance:
			patrol_target = candidate
			return
			
	patrol_target = body.global_position

func chase(delta: float) -> void:
	if not data.player_detected:
		idle(delta)
		return
	var direction := _direction_to(data.player_pos)
	data.facing_dir = direction
	var speed:= data.walk_speed * data.modifiers.get_speed_scale()
	var target_velocity:= direction * speed
	locomotion = locomotion.move_toward(target_velocity, data.acceleration * delta)
	_commit()

## Heads for where the player was last seen. Arriving to find nothing, or
## getting stuck on the way, gives up and drops back to patrolling.
func search(delta: float) -> void:
	# Only time spent getting nowhere counts towards giving up, so a long walk
	# to a far-off spot isn't cut short. Only a stuck search ends early.
	if body.global_position.distance_to(_search_anchor) > search_progress_distance:
		_search_anchor = body.global_position
		search_timer = 0.0
	else:
		search_timer += delta
	var direction:= _direction_to(data.last_seen_pos)
	var arrived:= body.global_position.distance_to(data.last_seen_pos) < arrival_threshold
	if _has_navigation() and agent.is_navigation_finished():
		arrived = true
	if arrived or search_timer >= search_timeout:
		data.has_last_seen = false
		idle(delta)
		return
	data.facing_dir = direction
	var speed:= data.walk_speed * data.modifiers.get_speed_scale()
	var target_velocity:= direction * speed
	locomotion = locomotion.move_toward(target_velocity, data.acceleration * delta)
	_commit()

func attack(delta: float) -> void:
	if data.player_detected:
		data.facing_dir = (data.player_pos - body.global_position).normalized()
	idle(delta) #stands still, attack system spawns hitbox and does timing
	
func attack_cooldown(delta: float) -> void:
	# Tracks while waiting — only the swing itself is committed.
	if data.player_detected:
		data.facing_dir = (data.player_pos - body.global_position).normalized()
	idle(delta)

## Which way to walk to reach `target`: along the navigation path when the
## level has one, straight at it when it doesn't.
func _direction_to(target: Vector2) -> Vector2:
	if not _has_navigation():
		return (target - body.global_position).normalized()
	if target.distance_to(_last_target) > repath_distance:
		_last_target = target
		agent.target_position = target
	return (agent.get_next_path_position() - body.global_position).normalized()

## True once the level's navigation map exists and has something on it. A
## level without one falls back to straight-line movement rather than
## leaving its enemies frozen.
func _has_navigation() -> bool:
	if _navigation_ready: return true
	if agent == null: return false
	var map:= agent.get_navigation_map()
	_navigation_ready = NavigationServer2D.map_get_iteration_id(map) > 0 \
		and not NavigationServer2D.map_get_regions(map).is_empty()
	return _navigation_ready

func _avoiding() -> bool:
	return agent != null and agent.avoidance_enabled \
		and NavigationServer2D.map_get_iteration_id(agent.get_navigation_map()) > 0

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	_safe_velocity = safe_velocity

func _on_state_changed(from: EnemyData.State, to: EnemyData.State) -> void:
	if to == EnemyData.State.PATROL:
		patrol_timer = 0.0
		pick_patrol_target()
	elif to == EnemyData.State.SEARCH:
		search_timer = 0.0
		_search_anchor = body.global_position
