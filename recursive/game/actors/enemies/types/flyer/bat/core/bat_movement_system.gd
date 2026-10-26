class_name BatMovementSystem

extends EnemyMovementSystem

## How the bat flies around the player: circling, diving straight in, and
## pulling straight back out. Those three ignore pathfinding (the bat's in
## the open, close to the player); getting there uses the flyer map.

## How hard circling pulls back to the right distance from the player.
const RADIUS_PULL := 3.0

var bat: Bat
var _orbit:= 1.0
var _dive_direction:= Vector2.ZERO

func _init(body_ref: Bat, data_ref: EnemyData) -> void:
	super(body_ref, data_ref)
	bat = body_ref

func circle(delta: float) -> void:
	var from_player:= body.global_position - data.player_pos
	if from_player.length() < 1.0:
		from_player = Vector2.RIGHT
	var around:= from_player.normalized().orthogonal() * _orbit
	var correction:= from_player.normalized() * (bat.circle_radius - from_player.length()) * RADIUS_PULL
	var target_velocity:= (around * data.walk_speed + correction).limit_length(data.walk_speed)
	data.facing_dir = -from_player.normalized()
	_fly(target_velocity, delta)

## Straight at where the player was when the dive began, fast.
func attack(delta: float) -> void:
	data.facing_dir = _dive_direction
	_fly(_dive_direction * bat.dive_speed, delta)

func retreat(delta: float) -> void:
	var away:= (body.global_position - data.player_pos).normalized()
	data.facing_dir = -away
	_fly(away * data.walk_speed, delta)

func _fly(target_velocity: Vector2, delta: float) -> void:
	locomotion = locomotion.move_toward(target_velocity * data.modifiers.get_speed_scale(), data.acceleration * delta)
	_commit()

func _on_state_changed(from: EnemyData.State, to: EnemyData.State) -> void:
	super(from, to)
	match to:
		EnemyData.State.ATTACK:
			_dive_direction = (data.player_anchor - body.global_position - Vector2(0, -24)).normalized()
		EnemyData.State.CIRCLE:
			# Either way round, so a group doesn't orbit in lockstep.
			_orbit = 1.0 if randf() < 0.5 else -1.0
