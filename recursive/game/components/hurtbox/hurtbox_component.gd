extends Area2D

var _on_damage_received: Callable

signal knockback_received(direction: Vector2, strength: float, decay: float)

#gets damage received from opposition hitbox, passes it to the HealthComponent
func receive_damage(damage: float, attacker: Area2D) -> void:
	if _on_damage_received:
		_on_damage_received.call(damage)
	
	if attacker.has_method("get_knockback_direction"):
		var direction: Vector2 = attacker.get_knockback_direction()
		var strength:float = attacker.knockback_strength
		var decay: float = attacker.knockback_decay
		if strength > 0.0:
			knockback_received.emit(direction, strength, decay)
