class_name BatStateMachine

extends EnemyStateMachine

## Circle, dive, pull back; see Bat.

var bat: Bat

func _init(cooldown_duration: float, bat_ref: Bat) -> void:
	super(cooldown_duration)
	bat = bat_ref

## Every dive is followed by pulling back out.
func _after_attack(data: EnemyData) -> EnemyData.State:
	data.retreat_left = bat.retreat_time
	return EnemyData.State.RETREAT

func _resolve_behaviour(data: EnemyData) -> EnemyData.State:
	if data.flee_left > 0.0:
		return EnemyData.State.FLEE
	if not data.player_detected:
		return EnemyData.State.SEARCH if data.has_last_seen else EnemyData.State.PATROL
	# A dive, once started, runs its course.
	if data.current_state == EnemyData.State.ATTACK:
		return EnemyData.State.ATTACK
	if data.retreat_left > 0.0:
		return EnemyData.State.RETREAT
	var distance:= bat.global_position.distance_to(data.player_pos)
	if distance > bat.circle_radius + 40.0:
		return EnemyData.State.CHASE
	if data.attack_cooldown_timer <= 0.0 and data.has_line_of_sight:
		return EnemyData.State.ATTACK
	return EnemyData.State.CIRCLE
