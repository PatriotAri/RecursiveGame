extends Area2D

#health component node can be selected in editor now
@export var health: Node

#gets damage received from opposition hitbox, passes it to the HealthComponent
func receive_damage(damage: float, attacker: Area2D) -> void:
	if health:
		#passes damaged received to apply_damage function in HealthComponent
		health.apply_damage(damage)
