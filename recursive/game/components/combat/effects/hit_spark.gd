class_name HitSpark

extends CPUParticles2D

## A short burst of sparks where a hit lands. Spawn with HitSpark.spawn().

static func spawn(parent: Node, at: Vector2, color := Color.WHITE) -> void:
	if parent == null: return
	var spark := HitSpark.new()
	spark.color = color
	spark.z_index = 40
	parent.add_child(spark)
	spark.global_position = at
	spark.emitting = true

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
	# Fades out over its life rather than popping off.
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	color_ramp = fade
	finished.connect(queue_free)
