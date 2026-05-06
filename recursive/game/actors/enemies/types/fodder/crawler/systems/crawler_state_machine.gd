class_name CrawlerStateMachine

var attack_cooldown_timer := 0.0
var attack_cooldown_duration := 1.5

func update(data: EnemyData, delta: float) -> void:
	var new_state := _resolve_state(data, delta)

	if new_state != data.current_state:
		data.previous_state = data.current_state
		data.current_state = new_state
		data.state_just_changed = true
	else:
		data.state_just_changed = false

func _resolve_state(data: EnemyData, delta: float) -> EnemyData.State:
	if data.current_state == data.State.DIED:
		return data.State.DIED
	
	if data.is_dead:
		return data.State.DIED
		
	if data.is_hurt:
		data.attack_finished = false
		return data.State.HURT
	# If currently attacking and the swing landed, enter cooldown
	if data.current_state == data.State.ATTACK and data.attack_finished:
		data.attack_finished = false
		attack_cooldown_timer = attack_cooldown_duration
		return data.State.ATTACK_COOLDOWN

	# If in cooldown, count down
	if data.current_state == data.State.ATTACK_COOLDOWN:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer > 0.0:
			return data.State.ATTACK_COOLDOWN

	# Normal resolution
	if data.player_detected and data.in_attack_range:
		return data.State.ATTACK
	elif data.player_detected:
		return data.State.CHASE
	else:
		return data.State.PATROL
