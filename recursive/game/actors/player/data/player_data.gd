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
#!!!rename to turn speed!!!
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

#movement modifiers (knockback, slows, dashes, etc.)
var modifiers:= MovementModifierStack.new()

#read/written by AttackSystem
var is_attacking:= false

#read/written by HealthUtility
var health_regen_points: int = 2
var max_health: int = 20
var current_health: int = max_health

#read/written by StaminaUtility
var stamina_regen_points: int = 2
var current_stamina: int = max_stamina
var max_stamina: int = 20

#read/written by ManaUtility
var mana_regen_points: int = 2
var current_mana: int = max_mana
var max_mana: int = 10
