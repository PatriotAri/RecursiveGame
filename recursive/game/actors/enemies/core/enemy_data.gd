class_name EnemyData

extends ActorData

enum State {
	IDLE,
	CHASE,
	PATROL,
	ATTACK,
	ATTACK_COOLDOWN,
	HURT,
	DIED,
	FLEE, #always append, never insert in the middle
}

#read/written by DetectionSystem
var player_detected:= false
var in_attack_range:= false
var player_pos:= Vector2.ZERO
#the middle of the player's hurtbox — used for range checks
var player_anchor:= Vector2.ZERO

#read/written by state machine
var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var state_just_changed:= false
var attack_finished:= false
#counts down every frame in every state, so an interrupted swing can't
#discard the cooldown it already owes
var attack_cooldown_timer:= 0.0

#read/written by movement system, seeded from Enemy's exports
var patrol_speed:= 50.0
var walk_speed:= 65.0

#read/written by Enemy, read by state machine
## Low on health with the player close. Only ever true for a type that flees.
var in_danger:= false
## Counts how long the current flee has lasted; FLEE gives up at the limit.
var flee_timer:= 0.0
## After giving up, fleeing is blocked until this runs out — a cornered
## enemy turns and fights instead of pressing into the wall forever.
var flee_block_timer:= 0.0
