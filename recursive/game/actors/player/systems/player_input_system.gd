class_name PlayerInputSystem

func update(data: PlayerData) -> void:
	var move_vector := Input.get_vector(
		"player_left", "player_right", "player_up", "player_down")
	
	data.move_vector = move_vector
	
	data.is_running = Input.is_action_pressed("player_run")
	
	data.attack_requested = Input.is_action_just_pressed("player_attack")
