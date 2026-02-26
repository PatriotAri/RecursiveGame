class_name EnemyStateMachine

enum State {
	IDLE,
	CHASE,
	PATROL,
	ATTACK,
	ATTACK_COOLDOWN,
}

var attack_cooldown_timer := 0.0
var attack_cooldown_duration := 1.5

func update(data: EnemyFodderData, delta: float) -> void:
	var new_state := _resolve_state(data, delta)

	if new_state != data.current_state:
		data.previous_state = data.current_state
		data.current_state = new_state
		data.state_just_changed = true
	else:
		data.state_just_changed = false

func _resolve_state(data: EnemyFodderData, delta: float) -> State:
	# If currently attacking and the swing landed, enter cooldown
	if data.current_state == State.ATTACK and data.attack_finished:
		data.attack_finished = false
		attack_cooldown_timer = attack_cooldown_duration
		return State.ATTACK_COOLDOWN

	# If in cooldown, count down
	if data.current_state == State.ATTACK_COOLDOWN:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer > 0.0:
			return State.ATTACK_COOLDOWN

	# Normal resolution
	if data.player_detected and data.in_attack_range:
		return State.ATTACK
	elif data.player_detected:
		return State.CHASE
	else:
		return State.PATROL
