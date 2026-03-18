class_name PlayerInputSystem

"""
creates update function to be called 
in player.gd and write input update to PlayerData.
"""
func update(data: PlayerData) -> void:
	var move_vector := Input.get_vector(
		"player_left", "player_right", "player_up", "player_down")

	data.move_vector = move_vector

	#run intent
	data.is_running = Input.is_action_pressed("player_run")
	
	#attack intent
	data.attack_requested = Input.is_action_just_pressed("player_attack")
