class_name PlayerMovementSystem

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref

"""
Writes to player data, delta here for changes
to speed like acceleration, deceleration, knockback, etc.
"""

func update(data: PlayerData, delta: float) -> void:
	var speed := data.base_run_speed if data.is_running else data.base_walk_speed
	var target_velocity:= data.move_vector * speed
	
	if target_velocity.length() > 0.0:
		#accelerate player
		player.velocity = player.velocity.move_toward(target_velocity, data.acceleration * delta)
	else:
		#decelerates to zero
		player.velocity = player.velocity.move_toward(Vector2.ZERO, data.friction * delta)
	#Moves "player"(characterBody2D) using its velocity and resolves collisions by sliding.
	player.move_and_slide()
