class_name EnemyData

enum State {
	IDLE,
	CHASE,
	PATROL,
	ATTACK,
	ATTACK_COOLDOWN,
	HURT,
	DIED,
}

var is_hurt:= false
var is_dead:= false

#read/written by DetectionSystem
var player_detected:= false
var in_attack_range:= false
var player_pos:= Vector2.ZERO

#read/written by state machine
var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var state_just_changed:= false
var attack_finished:= false

#read/written by movement system
var patrol_speed:= 50.0
var walk_speed:= 65.0
var run_speed:= 130.0
var last_facing:= Vector2.ZERO
var acceleration:= 500.0 #px/s^2
var friction:= 600.0 #px/s^2
