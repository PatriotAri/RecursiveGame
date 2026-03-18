extends Area2D

#health component node can be selected in editor now
@export var health: HealthComponent

signal knockback_received(direction: Vector2, strength: float, decay: float)

#gets damage received from opposition hitbox, passes it to the HealthComponent
func receive_damage(damage: float, attacker: Area2D) -> void:
	if health:
		#passes damaged received to apply_damage function in HealthComponent
		health.apply_damage(damage)
	
	if attacker.has_method("get_knockback_direction"):
		var direction: Vector2 = attacker.get_knockback_direction()
		var strength:float = attacker.knockback_strength
		var decay: float = attacker.knockback_decay
		if strength > 0.0:
			knockback_received.emit(direction, strength, decay)
