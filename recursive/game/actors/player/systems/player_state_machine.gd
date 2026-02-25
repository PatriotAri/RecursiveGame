class_name PlayerStateMachine

#writes updated state and facing direction to PlayerData
func update(data: PlayerData) -> void:
	_resolve_state(data)
	_resolve_facing(data)

#reads move_vector from PlayerData
func _resolve_state(data: PlayerData) -> void:
	if data.is_attacking:
		data.current_state = PlayerData.State.ATTACK
	elif data.move_vector == Vector2.ZERO:
		data.current_state = PlayerData.State.IDLE
	else:
		data.current_state = PlayerData.State.WALK

#reads move_vector from PlayerData
func _resolve_facing(data: PlayerData) -> void:
	#prevents direction change when attackinga
	if data.is_attacking:
		return
	#sets FACING direction based on move_vector from PlayerData
	if data.move_vector != Vector2.ZERO:
		data.facing_dir = data.move_vector
