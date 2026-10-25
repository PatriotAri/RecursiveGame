class_name EnemyMovementSystem

#references
var body: Enemy
var data: EnemyData

#patrol variables
var patrol_wait_time: float
var patrol_timer: float
var patrol_target:= Vector2.ZERO
var min_patrol_distance: float
var max_attempts:= 10
var arrival_threshold:= 5.0
# The enemy's own intent-driven velocity. Impulses are layered onto
# body.velocity for one frame only and never stored back here.
var locomotion := Vector2.ZERO

## How far ahead a fleeing enemy aims each frame. Far enough that the path
## bends round walls, near enough that it keeps re-aiming as the player moves.
const FLEE_LOOKAHEAD := 96.0

func _init(body_ref: Enemy, data_ref: EnemyData) -> void:
	body = body_ref
	data = data_ref

	patrol_wait_time = body.patrol_wait_time
	patrol_timer = body.patrol_timer
	min_patrol_distance = body.min_patrol_distance

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
		EnemyData.State.FLEE:
			flee(delta)
		EnemyData.State.ATTACK:
			attack(delta)
		EnemyData.State.ATTACK_COOLDOWN:
			attack_cooldown(delta)
		_:
			idle(delta)

# Single exit point for movement, so the impulse and spacing push are applied
# once per frame no matter which state ran.
func _commit() -> void:
	body.velocity = locomotion + data.modifiers.get_impulse_sum() + body.steering_velocity()
	body.move_and_slide()

func idle(delta: float) -> void:
	locomotion = locomotion.move_toward(Vector2.ZERO, data.friction * delta)
	_commit()

## Accelerates toward `target` along a path round walls (or straight, with no
## navmesh) and faces the way it's going.
func _move_toward(target: Vector2, speed: float, delta: float) -> void:
	var next := body.next_path_position(target)
	var direction := next - body.global_position
	if direction.length_squared() < 0.01:
		idle(delta)
		return
	direction = direction.normalized()
	data.facing_dir = direction
	var target_velocity := direction * speed * data.modifiers.get_speed_scale()
	locomotion = locomotion.move_toward(target_velocity, data.acceleration * delta)
	_commit()

func patrol(delta: float) -> void:
	var direction:= patrol_target - body.global_position
	#the "arrival_threshold" tells the enemy when its within the range,
	#act like it's reached the patrol point. This prevents the enemy from
	#jittering on the patrol point or not being able to find the patrol point all together.
	if direction.length() < arrival_threshold:
		idle(delta)
		patrol_timer += delta
		if patrol_timer >= patrol_wait_time:
			patrol_timer = 0.0
			pick_patrol_target()
	else:
		_move_toward(patrol_target, data.patrol_speed, delta)

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
		# Snapped onto the navmesh, so a point picked inside a wall becomes
		# the nearest reachable spot instead of somewhere to grind against.
		candidate = body.closest_walkable(candidate)
		if body.global_position.distance_to(candidate) >= min_patrol_distance:
			patrol_target = candidate
			return

	patrol_target = body.global_position

func chase(delta: float) -> void:
	if not data.player_detected:
		idle(delta)
		return
	_move_toward(data.player_pos, data.walk_speed, delta)

func flee(delta: float) -> void:
	if not data.player_detected:
		idle(delta)
		return
	var away := body.global_position - data.player_pos
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	var goal := body.closest_walkable(body.global_position + away.normalized() * FLEE_LOOKAHEAD)
	_move_toward(goal, body.flee_speed, delta)

func attack(delta: float) -> void:
	if data.player_detected:
		data.facing_dir = (data.player_pos - body.global_position).normalized()
	idle(delta) #stands still, attack system spawns hitbox and does timing

func attack_cooldown(delta: float) -> void:
	if not data.player_detected:
		idle(delta)
		return
	# A ranged enemy steps back out of reach between shots.
	var away := body.global_position - data.player_pos
	if body.preferred_distance > 0.0 and away.length() < body.preferred_distance:
		var goal := body.closest_walkable(body.global_position + away.normalized() * FLEE_LOOKAHEAD)
		_move_toward(goal, data.walk_speed, delta)
	else:
		idle(delta)
	# Tracks while waiting — only the swing itself is committed. Set after
	# moving, so backing off doesn't turn its back on the player.
	data.facing_dir = -away.normalized()

func _on_state_changed(from: EnemyData.State, to: EnemyData.State) -> void:
	if to == EnemyData.State.PATROL:
		patrol_timer = 0.0
		pick_patrol_target()
