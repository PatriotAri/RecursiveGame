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

#hitstun, ticked down in player.gd - replaces the old animation_finished hook
var hurt_timer:= 0.0
#bumped on every hit so the animation can tell a rehit from a held state
var hurt_seq:= 0

#!!!rename to turn speed!!!
var facing_turn_speed:= 35.0

#read/written by InputSystem (player intent)
var move_vector:= Vector2.ZERO
var is_running:= false
var attack_requested:= false
var interact_requested:= false

#read/written by StateMachine 
var current_state: State = State.IDLE
var facing_dir:= Vector2.DOWN
var facing_string: String = "S"

#read/written by ModifierSystem
var walk_speed: float
var run_speed: float

#stamina costs — derived from base + equipment, read by player.gd
var sprint_stamina_cost: float
var attack_stamina_modifier: int = 0

#flat damage reduction — summed from equipment, read by player.gd
var armor: int = 0

#acceleration/deceleration
var acceleration: float
var friction: float

#movement modifiers (knockback, slows, dashes, etc.)
var modifiers:= MovementModifierStack.new()

#read/written by AttackSystem
var is_attacking:= false
## Which registered attack a swing spawns. Points at the equipped weapon's
## attack, or back at unarmed when nothing is equipped.
var current_attack: StringName = &"unarmed"
## The animation set that attack uses. Set with current_attack, so the two
## can never disagree about which weapon is in hand.
var animation_prefix := ""
## A projectile attack that's been let go of and is cooling down: true from
## release until its cooldown ends. The thrown weapon or readied spell isn't
## shown in the hand meanwhile.
var cooling_down:= false

#spells, read/written by SpellSystem
## Learned from tomes, in the order learned.
var known_spells: Array[Spell] = []
## What's on keys 1 to 4. Null for an empty key.
var spell_slots: Array[Spell] = [null, null, null, null]
## The spell in hand, cast with the attack button. Null when none is readied.
var readied_spell: Spell
## The melee weapon put away to free the hands for a spell. The spell's key
## puts the spell away and brings this back.
var stowed_weapon: EquippableItem
## Which spell key (0 to 3) was pressed this frame, or -1. Written by
## InputSystem.
var spell_key_pressed:= -1

#read/written by StatSystem
var is_exhausted:= false

#inventory
var inventory := Inventory.new()

#equipment
var equipment := Equipment.new()
