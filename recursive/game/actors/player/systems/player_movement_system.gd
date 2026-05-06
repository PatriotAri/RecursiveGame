class_name PlayerMovementSystem

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref

func update(data: PlayerData, delta: float) -> void:
	data.modifiers.update(delta)
	
	#velocity override takes full control (dash, charge, etc.)
	if data.modifiers.has_velocity_override():
		player.velocity = data.modifiers.get_velocity_override()
		player.move_and_slide()
		return
	
	var speed := data.run_speed if data.is_running else data.walk_speed
	
	#apply speed scale modifiers (slows, buffs)
	speed *= data.modifiers.get_speed_scale()
	
	var target_velocity:= data.move_vector * speed
	
	if target_velocity.length() > 0.0:
		#accelerate player
		player.velocity = player.velocity.move_toward(target_velocity, data.acceleration * delta)
	else:
		#decelerates to zero
		player.velocity = player.velocity.move_toward(Vector2.ZERO, data.friction * delta)
		
	#layer impulse modifiers on top (knockback, recoil)
	player.velocity += data.modifiers.get_impulse_sum()
	
	player.move_and_slide()
