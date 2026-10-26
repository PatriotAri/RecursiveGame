class_name AttackSpec

extends Resource

const DIRECTIONS := ["E", "W", "N", "S", "NE", "NW", "SE", "SW"]

enum DamageType {PHYSICAL, FIRE} #always append enum, never insert in middle

## Everything one attack needs: what to spawn, where to put it, how hard it
## hits, and how long it lasts. Built in code today; save as a .tres later to
## tune attacks in the Inspector instead of editing scripts.

@export var scene: PackedScene
@export var offsets: HitboxOffsetData

@export_group("Damage")
@export var damage := 1.0
## What kind of damage it deals. Damage-type enchantments boost one kind.
@export var damage_type := DamageType.PHYSICAL
@export var knockback_strength := 50.0
@export var knockback_decay := 800.0
## Rolled per target, per hit. 1.0 reproduces the old always-stagger behaviour.
@export_range(0.0, 1.0) var hitstun_chance := 1.0
@export_range(0.0, 1.0) var knockback_chance := 1.0

@export_group("Timing")
@export var windup_time := 0.1
@export var lifetime := 0.1

@export_group("Cost")
@export var attack_stamina_cost := 5
## Spent when the attack starts. Without enough, the attack is refused.
@export var mana_cost := 0

@export_group("Audio")
## Played when the attack starts — for an enemy, its telegraph.
@export var swing_sound: SoundEffect
## Played at each target the attack connects with.
@export var hit_sound: SoundEffect

## What the spawned attack's art is drawn through, e.g. a thrown dagger
## recoloured to its material. Set on a modified copy, never saved.
var visual_material: Material

@export_group("Geometry")
## Radius of the collision shape inside `scene`. Stored here rather than read
## from the scene so a commit range can be computed without instancing one.
## Keep in sync by hand if you resize the hitbox shape in the editor.
@export var reach_radius := 10.0

## A copy with the attacker's modifiers applied: a staff's amplify and their
## enchantments. This spec is a shared resource, so it's never changed itself.
func modified(damage_scale: float, mana_scale := 1.0, area_scale := 1.0, extra_pierce := 0) -> AttackSpec:
	var copy := duplicate() as AttackSpec
	copy.damage = damage * damage_scale
	# Snapped first so float noise (3 x 1.1 = 3.3000000000000003) can't round
	# a cost up a whole point.
	copy.mana_cost = ceili(snappedf(mana_cost * mana_scale, 0.001))
	return copy

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
