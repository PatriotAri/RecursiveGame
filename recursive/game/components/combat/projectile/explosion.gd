class_name Explosion

extends HitboxBase

## A one-off burst of damage in a circle, plus its own visual. Built in code
## (no scene) by whatever explodes, so radius and damage can come from the
## caller. Damage is live for `lifetime`; the visual keeps fading after that.

@export var radius:= 40.0
@export var color:= Color(1.0, 0.55, 0.15)
@export var visual_time:= 0.35

func _ready() -> void:
	# Only ever detects; nothing needs to detect an explosion.
	collision_layer = 0
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	super()
	begin_attack()

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if not _active and _elapsed >= windup_time and _elapsed < windup_time + lifetime:
		_activate()
	elif _active and _elapsed >= windup_time + lifetime:
		_active = false
		set_deferred("monitoring", false)
	queue_redraw()
	if _elapsed >= maxf(visual_time, windup_time + lifetime):
		queue_free()

## Shoves outward from the centre, rather than in one shared direction.
func _on_area_entered(area: Area2D) -> void:
	var away := area.global_position - global_position
	knockback_direction = away if away != Vector2.ZERO else Vector2.RIGHT
	super(area)

func _draw() -> void:
	var t := clampf(_elapsed / visual_time, 0.0, 1.0)
	var grow := 0.4 + 0.6 * (1.0 - pow(1.0 - t, 3.0))
	var fade := 1.0 - t
	draw_circle(Vector2.ZERO, radius * grow, Color(color, 0.55 * fade))
	draw_circle(Vector2.ZERO, radius * grow * 0.6, Color(1.0, 0.9, 0.5, 0.7 * fade))
	draw_arc(Vector2.ZERO, radius * grow, 0.0, TAU, 32, Color(color, fade), 2.0)
