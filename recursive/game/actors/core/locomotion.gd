class_name Locomotion

## An actor's own intent-driven velocity, and the one place it meets the
## movement modifiers. Impulses (knockback) and steering are layered onto the
## body for the frame they apply and never stored back into `velocity`.

var velocity:= Vector2.ZERO

func accelerate(target: Vector2, rate: float, delta: float) -> void:
	velocity = velocity.move_toward(target, rate * delta)

func brake(rate: float, delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, rate * delta)

## Lets a velocity override (a dash, a swoop) take full control. Returns true
## when one did, having already moved the body.
func run_override(body: CharacterBody2D, modifiers: MovementModifierStack) -> bool:
	if not modifiers.has_velocity_override():
		return false
	velocity = modifiers.get_velocity_override()
	body.velocity = velocity
	body.move_and_slide()
	return true

## Moves the body: intent, plus this frame's impulses, plus any extra
## steering. The single exit point, so each is applied exactly once a frame.
func commit(body: CharacterBody2D, modifiers: MovementModifierStack, extra:= Vector2.ZERO) -> void:
	body.velocity = velocity + modifiers.get_impulse_sum() + extra
	body.move_and_slide()
