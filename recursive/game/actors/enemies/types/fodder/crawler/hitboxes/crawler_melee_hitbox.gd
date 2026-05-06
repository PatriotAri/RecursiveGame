extends HitboxBase

func get_knockback_direction() -> Vector2:
	return knockback_direction.normalized()
