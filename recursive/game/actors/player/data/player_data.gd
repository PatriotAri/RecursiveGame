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
var facing_turn_speed:= 35.0

#read/written by InputSystem (player intent)
var move_vector:= Vector2.ZERO
var is_running:= false
var attack_requested:= false

#read/written by StateMachine 
var current_state: State = State.IDLE
var facing_dir:= Vector2.DOWN
var facing_string: String = "down"

#read/written by ModifierSystem
var walk_speed: float
var run_speed: float

#acceleration/deceleration
var acceleration: float
var friction: float

var backpedal_penalty: float

#movement modifiers (knockback, slows, dashes, etc.)
var modifiers:= MovementModifierStack.new()

#read/written by AttackSystem
var is_attacking:= false
