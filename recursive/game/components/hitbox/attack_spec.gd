class_name AttackSpec

extends Resource

## Everything one attack needs: what to spawn, where to put it, how hard it
## hits, and how long it lasts. Built in code today; save as a .tres later to
## tune attacks in the Inspector instead of editing scripts.

@export var scene: PackedScene
@export var offsets: HitboxOffsetData

@export_group("Damage")
@export var damage := 1.0
@export var knockback_strength := 50.0
@export var knockback_decay := 800.0

@export_group("Timing")
@export var windup_time := 0.1
@export var lifetime := 0.1

func offset_for(facing: Vector2) -> Vector2:
	if offsets == null:
		return Vector2.ZERO
	return offsets.get_offset(FacingHelper.facing_to_string(facing))
