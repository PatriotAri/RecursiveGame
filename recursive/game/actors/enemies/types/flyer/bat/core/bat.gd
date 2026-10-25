class_name Bat

extends Enemy

## Flyer: ignores walls and the navmesh (its collision mask is empty in the
## scene, so it passes over everything), flutters as it flies, and swoops in
## on the player when it attacks.

@export_group("Flyer Tuning")
## Sideways flutter, in px/s, layered over its movement.
@export var flutter_strength:= 40.0
@export var flutter_rate:= 6.0
## Speed of the lunge at the start of an attack.
@export var swoop_speed:= 220.0
@export var swoop_time:= 0.18

var _flutter_phase:= randf() * TAU

func has_navigation() -> bool:
	# Straight lines only — that's the point of flying.
	return false

func steering_velocity() -> Vector2:
	_flutter_phase += flutter_rate * get_physics_process_delta_time()
	var side := data.facing_dir.orthogonal() if data.facing_dir != Vector2.ZERO else Vector2.RIGHT
	return super() + side * sin(_flutter_phase) * flutter_strength

func perform_attack(attack_name: StringName) -> void:
	super(attack_name)
	var toward := data.player_pos - global_position
	if toward != Vector2.ZERO:
		data.modifiers.add(MovementModifier.create_velocity_override(
			&"swoop", toward.normalized() * swoop_speed, swoop_time))
