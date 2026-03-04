class_name PlayerData

enum State {
	IDLE,
	WALK,
	ATTACK,
	HURT,
	DIED,
}

var is_hurt:= false
var is_dead:= false

#read/written by InputSystem (player intent)
var move_vector:= Vector2.ZERO
var is_running:= false
var attack_requested:= false

#read/written by StateMachine 
var current_state: State = State.IDLE
var facing_dir:= Vector2.DOWN
var facing_string: String = "down"

#read/written by ModifierSystem
var base_walk_speed:= 100.0
var base_run_speed:= 140.0

#read/written by AttackSystem
var is_attacking:= false
