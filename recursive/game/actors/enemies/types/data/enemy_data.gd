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

#hitstun, ticked down in crawler.gd — replaces the old animation_finished hook
var hurt_timer:= 0.0
#bumped on every hit so the animation can tell a re-hit from a held state
var hurt_seq:= 0

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

#read/written by movement system
var patrol_speed:= 50.0
var walk_speed:= 65.0
var run_speed:= 130.0
var facing_dir:= Vector2.ZERO
var acceleration:= 500.0 #px/s^2
var friction:= 600.0 #px/s^2

#movement modifiers (knockback, slows, dashes, etc.)
var modifiers := MovementModifierStack.new()
