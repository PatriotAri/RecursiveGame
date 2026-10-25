class_name HitSpark

extends CPUParticles2D

## A short burst of sparks where a hit lands. Pooled by the Effects
## autoload — burst() restarts the same node every time.

signal done(spark: HitSpark)

## One fade curve shared by every spark, instead of a new Gradient per hit.
static var _fade: Gradient

func _init() -> void:
	one_shot = true
	explosiveness = 1.0
	amount = 8
	lifetime = 0.25
	spread = 180.0
	gravity = Vector2.ZERO
	initial_velocity_min = 40.0
	initial_velocity_max = 90.0
	damping_min = 120.0
	damping_max = 160.0
	scale_amount_min = 1.5
	scale_amount_max = 2.5
	emitting = false
	if _fade == null:
		# Fades out over its life rather than popping off.
		_fade = Gradient.new()
		_fade.set_color(0, Color.WHITE)
		_fade.set_color(1, Color(1, 1, 1, 0))
	color_ramp = _fade
	finished.connect(func(): done.emit(self))

func burst(at: Vector2, tint: Color) -> void:
	global_position = at
	color = tint
	restart()
