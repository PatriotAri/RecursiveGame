class_name CrawlerStateMachine

var attack_cooldown_duration := 1.5

func _init(cooldown_duration := 1.5) -> void:
	attack_cooldown_duration = cooldown_duration

func update(data: EnemyData, delta: float) -> void:
	# Ticks in every state. The old version only counted down while
	# ATTACK_COOLDOWN was current, so any interruption threw the cooldown
	# away — and being hit mid-swing is the normal case, not the edge case.
	if data.attack_cooldown_timer > 0.0:
		data.attack_cooldown_timer -= delta

	var new_state := _resolve_state(data)

	if new_state != data.current_state:
		data.previous_state = data.current_state
		data.current_state = new_state
		data.state_just_changed = true
	else:
		data.state_just_changed = false

func _resolve_state(data: EnemyData) -> EnemyData.State:
	if data.current_state == EnemyData.State.DIED or data.is_dead:
		return EnemyData.State.DIED

	if data.is_hurt:
		if data.current_state == EnemyData.State.ATTACK:
			# An interrupted swing still owes its full cooldown.
			data.attack_finished = false
			data.attack_cooldown_timer = attack_cooldown_duration
		return EnemyData.State.HURT

	# Swing completed → cooldown
	if data.current_state == EnemyData.State.ATTACK and data.attack_finished:
		data.attack_finished = false
		data.attack_cooldown_timer = attack_cooldown_duration
		return EnemyData.State.ATTACK_COOLDOWN

	# In range but still cooling: hold position instead of walking in.
	if data.attack_cooldown_timer > 0.0 and data.player_detected and data.in_attack_range:
		return EnemyData.State.ATTACK_COOLDOWN

	# Normal resolution
	if data.player_detected and data.in_attack_range and data.attack_cooldown_timer <= 0.0:
		return EnemyData.State.ATTACK
	elif data.player_detected:
		return EnemyData.State.CHASE
	else:
		return EnemyData.State.PATROL
