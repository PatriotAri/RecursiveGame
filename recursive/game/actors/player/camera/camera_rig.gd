class_name CameraRig

extends Camera2D

## The player's camera: kept inside the current map, and jolted by hits.

var _shake_tween: Tween

## Stops at the edges of `bounds`. An empty rect lifts the limits.
func set_limits(bounds: Rect2) -> void:
	if bounds.size == Vector2.ZERO:
		bounds = Rect2(-10000000, -10000000, 20000000, 20000000)
	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)

## Jolts by up to `strength` px, settling over `duration`.
func shake(strength: float, duration: float) -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = create_tween()
	var steps := 4
	for i in steps:
		var falloff := 1.0 - float(i) / steps
		var jolt := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * falloff
		_shake_tween.tween_property(self, "offset", jolt, duration / (steps + 1))
	_shake_tween.tween_property(self, "offset", Vector2.ZERO, duration / (steps + 1))
