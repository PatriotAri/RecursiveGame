class_name Spitter

extends Enemy

## Ranged: keeps its distance and lobs acid. Commits to a shot from
## shoot_range with a clear line, then backs off to preferred_distance while
## it reloads.

@export_group("Ranged Tuning")
## Commits to a shot from this far. The shot itself — projectile, speed,
## range, sounds — is the `attack` resource.
@export var shoot_range:= 150.0

func _ready() -> void:
	primary_attack = &"spit"
	super()

func _compute_attack_range() -> float:
	return shoot_range
