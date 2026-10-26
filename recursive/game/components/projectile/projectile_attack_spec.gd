class_name ProjectileAttackSpec

extends AttackSpec

## An attack that gets let go of: thrown now, fired or cast later. The
## inherited timing still shapes the throw itself — windup_time is when it
## leaves the hand, lifetime is the follow-through after — and `scene` must
## be a Projectile. How fast and far it flies, and how soon the next one can
## go, are set here.

@export_group("Flight")
@export var speed := 400.0
## Gone after flying this far, so it can't hit what's off-screen.
@export var max_range := 300.0
## How many targets it passes through after the first. 0 stops at the first
## hit; an enchantment can raise it.
@export var pierce := 0
## Thrown from here, relative to the thrower's feet: about chest height.
@export var launch_offset := Vector2(0, -30)

@export_group("Cooldown")
## Seconds from one throw to the next. A thrown weapon is gone from the hand
## from release until this runs out.
@export var cooldown := 0.6

func flight_time() -> float:
	return max_range / maxf(speed, 1.0)

## A projectile can connect anywhere along its flight.
func min_reach() -> float:
	return max_range
