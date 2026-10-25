class_name ActorData

## State every actor shares, player and enemy alike. PlayerData and
## EnemyData extend this with their own.

var is_hurt:= false
var is_dead:= false

#hitstun, ticked down in actor.gd - replaces the old animation_finished hook
var hurt_timer:= 0.0
#bumped on every hit so the animation can tell a rehit from a held state
var hurt_seq:= 0

var facing_dir:= Vector2.ZERO

#acceleration/deceleration, px/s^2
var acceleration:= 500.0
var friction:= 600.0

#movement modifiers (knockback, slows, dashes, etc.)
var modifiers:= MovementModifierStack.new()
