class_name EnemyMovementSystem

#references
var body: CharacterBody2D
var data: EnemyFodderData
var state_machine: EnemyStateMachine
#patrol variables
var patrol_origin: Vector2
var patrol_offsets: Array[Vector2] = []
var patrol_points: Array[Vector2] = []
var current_patrol_index:= 0
var patrol_wait_time:= 3.5
var patrol_timer:= 0.0

#attack variables
var attack_performed:= false
var attack_timer:= 0.0

func _init(body_ref: CharacterBody2D, data_ref: EnemyFodderData) -> void:
	body = body_ref
	data = data_ref
	patrol_offsets.clear()
	if body.has_node("PatrolPoints"):
		for child in body.get_node("PatrolPoints").get_children():
			patrol_offsets.append(child.position)
	reset_patrol_origin(body.global_position)

func update(delta: float) -> void:
	#reads the flag set by state machine
	if data.state_just_changed:
		_on_state_changed(data.previous_state, data.current_state)

	match data.current_state:
		state_machine.State.PATROL:
			patrol(delta)
		state_machine.State.CHASE:
			chase(delta)
		state_machine.State.ATTACK:
			attack(delta)
		state_machine.State.ATTACK_COOLDOWN:
			attack_cooldown(delta)
		_:
			idle(delta)

func _stop() -> void:
	body.velocity = Vector2.ZERO
	body.move_and_slide()

func idle(_delta: float) -> void:
	_stop()

func patrol(delta: float) -> void:
	if patrol_points.is_empty():
		_stop()
		return
	var target_pos := patrol_points[current_patrol_index]
	var direction := target_pos - body.global_position
	if direction.length() < 5.0:
		patrol_timer += delta
		body.velocity = Vector2.ZERO
		if patrol_timer >= patrol_wait_time:
			patrol_timer = 0.0
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	else:
		var move_dir:= direction.normalized()
		data.last_facing = move_dir
		body.velocity = direction.normalized() * data.patrol_speed
	body.move_and_slide()

func reset_patrol_origin(new_origin: Vector2) -> void:
	patrol_origin = new_origin
	current_patrol_index = 0
	patrol_timer = 0.0
	body.velocity = Vector2.ZERO
	patrol_points.clear()
	for offset in patrol_offsets:
		patrol_points.append(patrol_origin + offset)

func chase(_delta: float) -> void:
	if not data.player_detected:
		_stop()
		return
	var direction := (data.player_pos - body.global_position).normalized()
	data.last_facing = direction
	body.velocity = direction * data.walk_speed
	body.move_and_slide()

func attack(delta: float) -> void:
	_stop()
	if not attack_performed:
		body.perform_melee_attack()
		attack_performed = true
	else:
		attack_timer += delta
		if attack_timer >= body.windup_time + body.lifetime:
			data.attack_finished = true

func attack_cooldown(_delta: float) -> void:
	_stop()

func _on_state_changed(from: EnemyStateMachine.State, to: EnemyStateMachine.State) -> void:
	if to == state_machine.State.ATTACK:
		attack_performed = false
		attack_timer = 0.0
	if from == state_machine.State.CHASE:
		reset_patrol_origin(body.global_position)
