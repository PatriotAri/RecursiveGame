class_name AttackSpec

extends Resource

const DIRECTIONS := ["right", "left", "up", "down",
	"up_right", "up_left", "down_right", "down_left"]

## Everything one attack needs: what to spawn, where to put it, how hard it
## hits, and how long it lasts. Built in code today; save as a .tres later to
## tune attacks in the Inspector instead of editing scripts.

@export var scene: PackedScene
@export var offsets: HitboxOffsetData

@export_group("Damage")
@export var damage := 1.0
@export var knockback_strength := 50.0
@export var knockback_decay := 800.0
## Rolled per target, per hit. 1.0 reproduces the old always-stagger behaviour.
@export_range(0.0, 1.0) var hitstun_chance := 1.0
@export_range(0.0, 1.0) var knockback_chance := 1.0

@export_group("Timing")
@export var windup_time := 0.1
@export var lifetime := 0.1

@export_group("Stamina")
@export var attack_stamina_cost := 5

@export_group("Geometry")
## Radius of the collision shape inside `scene`. Stored here rather than read
## from the scene so a commit range can be computed without instancing one.
## Keep in sync by hand if you resize the hitbox shape in the editor.
@export var reach_radius := 10.0

func offset_for(facing: Vector2) -> Vector2:
	if offsets == null:
		return Vector2.ZERO
	return offsets.get_offset(FacingHelper.facing_to_string(facing))

## Shortest distance from the actor's origin at which this attack can still
## touch something, across all eight facings.
##
## Deliberately the minimum, not the maximum: an enemy that commits at this
## range can reach in *every* direction, so it can never commit from further
## than its worst facing allows. Using the max would let it swing from 52px
## away and whiff whenever the target happened to be below it.
func min_reach() -> float:
	if offsets == null:
		return reach_radius
	var shortest := INF
	for dir in DIRECTIONS:
		shortest = minf(shortest, offsets.get_offset(dir).length())
	return shortest + reach_radius
