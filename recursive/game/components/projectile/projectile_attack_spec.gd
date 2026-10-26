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

@export_group("Blast")
## Bursts on hitting something or at the end of its range, damaging every
## target within this radius once. 0 means no blast: it only hits what it
## touches.
@export var blast_radius := 0.0
## Shown where it bursts, sized to the radius. Should be a Blast.
@export var blast_scene: PackedScene
@export var blast_sound: SoundEffect

func flight_time() -> float:
	return max_range / maxf(speed, 1.0)

func modified(damage_scale: float, mana_scale := 1.0, area_scale := 1.0, extra_pierce := 0) -> AttackSpec:
	var copy := super(damage_scale, mana_scale, area_scale, extra_pierce) as ProjectileAttackSpec
	copy.pierce = pierce + extra_pierce
	copy.blast_radius = blast_radius * area_scale
	return copy

## A projectile can connect anywhere along its flight.
func min_reach() -> float:
	return max_range
