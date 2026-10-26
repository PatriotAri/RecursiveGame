class_name Blast

extends Sprite2D

## The flash where a projectile bursts. Sized to the blast's radius, it swells
## a little and fades, then frees itself.

@export var duration := 0.25

func play(radius: float) -> void:
	var full := radius * 2.0 / maxf(texture.get_width() if texture else 1.0, 1.0)
	scale = Vector2.ONE * full * 0.6
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE * full, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)
