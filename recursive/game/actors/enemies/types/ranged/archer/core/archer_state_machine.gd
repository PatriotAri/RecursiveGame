class_name ArcherStateMachine

extends EnemyStateMachine

## Keeps its distance; see Archer.

var archer: Archer

func _init(cooldown_duration: float, archer_ref: Archer) -> void:
	super(cooldown_duration)
	archer = archer_ref

## Every shot is followed by a move to a new spot.
func _after_attack(data: EnemyData) -> EnemyData.State:
	data.reposition_left = archer.reposition_time
	return EnemyData.State.REPOSITION

func _resolve_behaviour(data: EnemyData) -> EnemyData.State:
	if not data.player_detected:
		return EnemyData.State.SEARCH if data.has_last_seen else EnemyData.State.PATROL
	# A draw that's started is finished: the arrow is already on the string.
	if data.current_state == EnemyData.State.ATTACK:
		return EnemyData.State.ATTACK
	var distance:= archer.global_position.distance_to(data.player_pos)
	if distance < archer.flee_distance:
		return EnemyData.State.FLEE
	if data.reposition_left > 0.0:
		return EnemyData.State.REPOSITION
	if not data.has_line_of_sight or distance > archer.far:
		return EnemyData.State.CHASE
	if data.attack_cooldown_timer <= 0.0:
		return EnemyData.State.ATTACK
	return EnemyData.State.ATTACK_COOLDOWN
