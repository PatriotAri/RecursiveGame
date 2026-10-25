class_name Hurtbox

extends Area2D

## Where an actor can be hit. Hitboxes find it on their target layer and call
## receive_damage(); the owning actor listens to the signals.

signal damaged(amount: float, apply_hitstun: bool)
signal knockback_received(direction: Vector2, strength: float, decay: float)

func receive_damage(damage: float, attacker: Area2D, apply_hitstun := true, apply_knockback := true) -> void:
	damaged.emit(damage, apply_hitstun)
	if not apply_knockback:
		return
	var hitbox := attacker as HitboxBase
	if hitbox == null or hitbox.knockback_strength <= 0.0:
		return
	knockback_received.emit(hitbox.get_knockback_direction(), hitbox.knockback_strength, hitbox.knockback_decay)
