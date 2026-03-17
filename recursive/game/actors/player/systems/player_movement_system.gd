class_name PlayerMovementSystem

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref

func update(data: PlayerData, delta: float) -> void:
	var speed := data.base_run_speed if data.is_running else data.base_walk_speed
	#direction facing speed penalty logic
	if data.move_vector.length() > 0.0 and data.facing_dir.length() > 0.0:
		#dot = 1.0 when moving toward cursor, -1.0 when backpedaling
		var dot:= data.move_vector.normalized().dot(data.facing_dir.normalized())
		# Remap: 1.0 → no penalty, -1.0 → full penalty
		# penalty_factor goes from 1.0 (aligned) down to (1.0 - backpedal_penalty) (opposed)
		var penalty_factor:= 1.0 - data.backpedal_penalty * (1.0 - dot) * 0.5
		speed *= penalty_factor
	
	var target_velocity:= data.move_vector * speed
	
	if target_velocity.length() > 0.0:
		#accelerate player
		player.velocity = player.velocity.move_toward(target_velocity, data.acceleration * delta)
	else:
		#decelerates to zero
		player.velocity = player.velocity.move_toward(Vector2.ZERO, data.friction * delta)
	#Moves "player"(characterBody2D) using its velocity and resolves collisions by sliding.
	player.move_and_slide()
