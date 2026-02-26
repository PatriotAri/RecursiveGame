class_name PlayerMovementSystem

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref

"""
Writes to player data, delta here for changes
to speed like acceleration, deceleration, knockback, etc.
"""

func update(data: PlayerData, delta: float) -> void:
	if data.is_attacking:
		player.velocity = Vector2.ZERO
	else:
		var speed := data.base_run_speed if data.is_running else data.base_walk_speed
		player.velocity = data.move_vector * speed

	#Moves "player"(characterBody2D) using its velocity and resolves collisions by sliding.
	player.move_and_slide()
