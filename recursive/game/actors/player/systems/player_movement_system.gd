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
	#direction facing speed penalty logic
	if data.move_vector.length() > 0.0 and data.facing_dir.length() > 0.0:
		#dot = 1.0 when moving toward cursor, -1.0 when backpedaling
		var dot:= data.move_vector.normalized().dot(data.facing_dir.normalized())
		# Remap: 1.0 → no penalty, -1.0 → full penalty
		# penalty_factor goes from 1.0 (aligned) down to (1.0 - backpedal_penalty) (opposed)
		var penalty_factor:= 1.0 - data.backpedal_penalty * (1.0 - dot) * 0.5
		speed *= penalty_factor
	
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
