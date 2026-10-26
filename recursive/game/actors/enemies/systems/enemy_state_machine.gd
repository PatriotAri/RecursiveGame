class_name EnemyStateMachine

var attack_cooldown_duration := 1.5

func _init(cooldown_duration := 1.5) -> void:
	attack_cooldown_duration = cooldown_duration

func update(data: EnemyData, delta: float) -> void:
	# Ticks in every state. The old version only counted down while
	# ATTACK_COOLDOWN was current, so any interruption threw the cooldown
	# away — and being hit mid-swing is the normal case, not the edge case.
	if data.attack_cooldown_timer > 0.0:
		data.attack_cooldown_timer -= delta
	data.flee_left = maxf(data.flee_left - delta, 0.0)
	data.reposition_left = maxf(data.reposition_left - delta, 0.0)
	data.retreat_left = maxf(data.retreat_left - delta, 0.0)

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
		return _after_attack(data)

	return _resolve_behaviour(data)

## What follows a finished attack. Holding ground by default; a type that
## moves after attacking (an archer repositioning, a flyer pulling back)
## overrides it.
func _after_attack(_data: EnemyData) -> EnemyData.State:
	return EnemyData.State.ATTACK_COOLDOWN

## What the enemy does when it isn't dead, staggered or finishing an attack.
## This is where types differ: override it to fight another way.
func _resolve_behaviour(data: EnemyData) -> EnemyData.State:
	# In range but still cooling: hold position instead of walking in.
	if data.attack_cooldown_timer > 0.0 and data.player_detected and data.in_attack_range:
		return EnemyData.State.ATTACK_COOLDOWN

	# Normal resolution
	if data.player_detected and data.in_attack_range and data.attack_cooldown_timer <= 0.0:
		return EnemyData.State.ATTACK
	elif data.player_detected:
		return EnemyData.State.CHASE
	elif data.has_last_seen:
		return EnemyData.State.SEARCH
	else:
		return EnemyData.State.PATROL
