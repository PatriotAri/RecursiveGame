class_name ArcherMovementSystem

extends EnemyMovementSystem

## How the archer gets around: a new spot after each shot, and backing off
## while it waits to shoot.

## How far round the player a new spot is, from where the archer stands.
const REPOSITION_ARC_MIN := deg_to_rad(25.0)
const REPOSITION_ARC_MAX := deg_to_rad(55.0)

var archer: Archer
var _spot:= Vector2.ZERO

func _init(body_ref: Archer, data_ref: EnemyData) -> void:
	super(body_ref, data_ref)
	archer = body_ref

func reposition(delta: float) -> void:
	var arrived:= body.global_position.distance_to(_spot) < arrival_threshold
	if _has_navigation() and agent.is_navigation_finished():
		arrived = true
	if arrived:
		data.reposition_left = 0.0
		attack_cooldown(delta)
		return
	var direction:= _direction_to(_spot)
	data.facing_dir = direction
	var target_velocity:= direction * data.walk_speed * data.modifiers.get_speed_scale()
	locomotion = locomotion.move_toward(target_velocity, data.acceleration * delta)
	_commit()

## Waiting to shoot: faces the player, and steps back if they're closer than
## it likes.
func attack_cooldown(delta: float) -> void:
	var to_player:= data.player_pos - body.global_position
	if to_player.length() >= archer.near:
		super(delta)
		return
	var direction:= _direction_to(body.global_position - to_player.normalized() * flee_reach)
	data.facing_dir = to_player.normalized()
	var target_velocity:= direction * data.walk_speed * data.modifiers.get_speed_scale()
	locomotion = locomotion.move_toward(target_velocity, data.acceleration * delta)
	_commit()

func _on_state_changed(from: EnemyData.State, to: EnemyData.State) -> void:
	super(from, to)
	if to == EnemyData.State.REPOSITION:
		_spot = _pick_spot()

## A spot at the archer's favourite distance from the player, part way round
## them from where it stands now, so it doesn't shoot twice from one place.
func _pick_spot() -> Vector2:
	var from_player:= body.global_position - data.player_pos
	if from_player.length() < 1.0:
		from_player = Vector2.RIGHT
	var turn:= randf_range(REPOSITION_ARC_MIN, REPOSITION_ARC_MAX) * (1.0 if randf() < 0.5 else -1.0)
	var spot:= data.player_pos + from_player.normalized().rotated(turn) * (archer.near + archer.far) / 2.0
	if _has_navigation():
		spot = NavigationServer2D.map_get_closest_point(agent.get_navigation_map(), spot)
	return spot
