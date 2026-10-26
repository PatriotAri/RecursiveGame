class_name PlayerInputSystem

const SPELL_ACTIONS: Array[StringName] = [&"spell_1", &"spell_2", &"spell_3", &"spell_4"]

func update(data: PlayerData) -> void:
	var move_vector := Input.get_vector(
		"player_left", "player_right", "player_up", "player_down")
	
	data.move_vector = move_vector
	
	data.is_running = Input.is_action_pressed("player_run")
	
	data.attack_requested = Input.is_action_just_pressed("player_attack")
	
	data.interact_requested = Input.is_action_just_pressed("interact")
	
	data.spell_key_pressed = -1
	for i in SPELL_ACTIONS.size():
		if Input.is_action_just_pressed(SPELL_ACTIONS[i]):
			data.spell_key_pressed = i
