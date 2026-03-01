class_name CrawlerMovementSystem

#references
var body: CharacterBody2D
var data: EnemyData

#patrol variables
var patrol_wait_time:= 3.5
var patrol_timer:= 0.0
var patrol_target:= Vector2.ZERO

#attack variables
var attack_performed:= false
var attack_timer:= 0.0

func _init(body_ref: CharacterBody2D, data_ref: EnemyData) -> void:
	body = body_ref
	data = data_ref

func update(delta: float) -> void:
	#reads the flag set by state machine
	if data.state_just_changed:
		_on_state_changed(data.previous_state, data.current_state)

	match data.current_state:
		CrawlerStateMachine.State.PATROL:
			patrol(delta)
		CrawlerStateMachine.State.CHASE:
			chase(delta)
		CrawlerStateMachine.State.ATTACK:
			attack(delta)
		CrawlerStateMachine.State.ATTACK_COOLDOWN:
			attack_cooldown(delta)
		_:
			idle(delta)

func idle(delta: float) -> void:
	body.velocity = Vector2.ZERO
	body.move_and_slide()

func patrol(delta: float) -> void:
	var direction:= patrol_target - body.global_position
	if direction.length() < 5.0:
		idle(delta)
		patrol_timer += delta
		if patrol_timer >= patrol_wait_time:
			patrol_timer = 0.0
			pick_patrol_target()
	else:
		data.last_facing = direction.normalized()
		body.velocity = direction.normalized() * data.patrol_speed
		body.move_and_slide()

func pick_patrol_target() -> void:
	if body.has_node("PatrolZone"):
		var zone:= body.get_node("PatrolZone")
		var shape:= zone.get_node("CollisionShape2D").shape as RectangleShape2D
		var half:= shape.size / 2.0
		patrol_target = body.global_position + Vector2(
			randf_range(-half.x, half.x),
			randf_range(-half.y, half.y)
		)
	else:
		patrol_target = body.global_position

func chase(delta: float) -> void:
	if not data.player_detected:
		idle(delta)
		return
	var direction := (data.player_pos - body.global_position).normalized()
	data.last_facing = direction
	body.velocity = direction * data.walk_speed
	body.move_and_slide()

func attack(delta: float) -> void:
	idle(delta)
	if not attack_performed:
		body.perform_melee_attack()
		attack_performed = true
	else:
		attack_timer += delta
		if attack_timer >= body.windup_time + body.lifetime:
			data.attack_finished = true

func attack_cooldown(delta: float) -> void:
	idle(delta)

func _on_state_changed(from: CrawlerStateMachine.State, to: CrawlerStateMachine.State) -> void:
	if to == CrawlerStateMachine.State.ATTACK:
		attack_performed = false
		attack_timer = 0.0
	if to == CrawlerStateMachine.State.PATROL:
		patrol_timer = 0.0
		pick_patrol_target()
