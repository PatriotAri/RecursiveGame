class_name EnemyData

enum State {
	IDLE,
	CHASE,
	PATROL,
	ATTACK,
	ATTACK_COOLDOWN,
	HURT,
	DIED,
	SEARCH,
	FLEE,
	REPOSITION,
	CIRCLE,
	RETREAT, #always append, never insert in middle
}

var is_hurt:= false
var is_dead:= false

#hitstun, ticked down in Enemy — replaces the old animation_finished hook
var hurt_timer:= 0.0
#bumped on every hit so the animation can tell a re-hit from a held state
var hurt_seq:= 0

#read/written by DetectionSystem
var player_detected:= false
var in_attack_range:= false
var player_pos:= Vector2.ZERO
#the middle of the player's hurtbox — used for range checks
var player_anchor:= Vector2.ZERO
#nothing on the Environment layer (walls, closed doors) between this enemy
#and the player. Low obstacles don't block it.
var has_line_of_sight:= false
#where the player was last known to be. Kept after aggro drops so the enemy
#can go and look (SEARCH); cleared when it finds the player or gives up
var has_last_seen:= false
var last_seen_pos:= Vector2.ZERO

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
## How fast it runs when fleeing.
var flee_speed:= 90.0
## Seconds left in a timed behaviour: fleeing, repositioning after a shot,
## pulling back after a dive. Set by the state machine, ticked by it too.
var flee_left:= 0.0
var reposition_left:= 0.0
var retreat_left:= 0.0
var facing_dir:= Vector2.ZERO
var acceleration:= 500.0 #px/s^2
var friction:= 600.0 #px/s^2

#movement modifiers (knockback, slows, dashes, etc.)
var modifiers := MovementModifierStack.new()
