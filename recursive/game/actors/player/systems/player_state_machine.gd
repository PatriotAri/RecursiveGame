class_name PlayerStateMachine

#writes updated state and facing direction to PlayerData
func update(data: PlayerData) -> void:
	_resolve_state(data)

#reads move_vector from PlayerData
func _resolve_state(data: PlayerData) -> void:
	if data.is_dead:
		data.current_state = PlayerData.State.DIED
	elif data.is_hurt:
		data.current_state = PlayerData.State.HURT
	elif data.is_attacking:
		data.current_state = PlayerData.State.ATTACK
	elif data.move_vector == Vector2.ZERO:
		data.current_state = PlayerData.State.IDLE
	else:
		data.current_state = PlayerData.State.WALK

func cache_facing(data: PlayerData) -> void:
	data.facing_string = FacingHelper.facing_to_string(data.facing_dir)
