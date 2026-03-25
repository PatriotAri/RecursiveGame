class_name CrawlerMovementSystem

#references
var body: CharacterBody2D
var data: EnemyData

#patrol variables
var patrol_wait_time: float
var patrol_timer: float
var patrol_target:= Vector2.ZERO
var min_patrol_distance: float
var max_attempts:= 10
var arrival_threshold:= 5.0

func _init(body_ref: CharacterBody2D, data_ref: EnemyData) -> void:
	body = body_ref
	data = data_ref
	
	patrol_wait_time = body.patrol_wait_time
	patrol_timer = body.patrol_timer
	min_patrol_distance = body.min_patrol_distance
	
	pick_patrol_target() #sets patrol point on crawler spawn

func update(delta: float) -> void:
	data.modifiers.update(delta)

	#velocity override takes full control
	if data.modifiers.has_velocity_override():
		body.velocity = data.modifiers.get_velocity_override()
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
		EnemyData.State.ATTACK:
			attack(delta)
		EnemyData.State.ATTACK_COOLDOWN:
			attack_cooldown(delta)
		_:
			idle(delta)

func idle(delta: float) -> void:
	body.velocity = body.velocity.move_toward(Vector2.ZERO, data.friction * delta)
	body.velocity += data.modifiers.get_impulse_sum()
	body.move_and_slide()

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
		var dir_norm:= direction.normalized()
		data.facing_dir = dir_norm
		var speed:= data.patrol_speed * data.modifiers.get_speed_scale()
		var target_velocity:= dir_norm * speed
		body.velocity = body.velocity.move_toward(target_velocity, data.acceleration * delta)
		body.velocity += data.modifiers.get_impulse_sum()
		body.move_and_slide()

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
		if body.global_position.distance_to(candidate) >= min_patrol_distance:
			patrol_target = candidate
			return
			
	patrol_target = body.global_position

func chase(delta: float) -> void:
	if not data.player_detected:
		idle(delta)
		return
	var direction := (data.player_pos - body.global_position).normalized()
	data.facing_dir = direction
	var speed:= data.walk_speed * data.modifiers.get_speed_scale()
	var target_velocity:= direction * speed
	body.velocity = body.velocity.move_toward(target_velocity, data.acceleration * delta)
	body.velocity += data.modifiers.get_impulse_sum()
	body.move_and_slide()

func attack(delta: float) -> void:
	idle(delta) #stands still, attack system spawns hitbox and does timing

func attack_cooldown(delta: float) -> void:
	idle(delta)

func _on_state_changed(from: EnemyData.State, to: EnemyData.State) -> void:
	if to == EnemyData.State.PATROL:
		patrol_timer = 0.0
		pick_patrol_target()
