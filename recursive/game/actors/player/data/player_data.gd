class_name PlayerData

extends ActorData

enum State {
	IDLE,
	WALK,
	ATTACK,
	HURT,
	DIED,
}

## How fast facing swings round to the movement direction.
var turn_speed:= 35.0

#read/written by InputSystem (player intent)
var move_vector:= Vector2.ZERO
var is_running:= false
var attack_requested:= false
var cast_requested:= false
var cycle_spell_requested:= false
var interact_requested:= false

#read/written by StateMachine 
var current_state: State = State.IDLE
## facing_dir as a FacingHelper index, worked out once per frame by the state
## machine for everything else to read.
var facing_index: int = FacingHelper.S

#read/written by ModifierSystem
var walk_speed: float
var run_speed: float

#stamina costs — derived from base + equipment, read by player.gd
var sprint_stamina_cost: float
var attack_stamina_modifier: int = 0

#read/written by AttackSystem
var is_attacking:= false
## Which registered attack a swing spawns. Points at the equipped weapon's
## attack, or back at unarmed when nothing is equipped.
var current_attack: StringName = &"unarmed"
## The selected spell's registered attack, or empty with nothing to cast.
## Set by PlayerSpellSystem.
var current_spell_attack: StringName = &""
## The attack actually in progress — current_attack for a swing,
## current_spell_attack for a cast. Set by PlayerAttackSystem.
var active_attack: StringName = &"unarmed"
## The animation set that attack uses. Set with current_attack, so the two
## can never disagree about which weapon is in hand.
var animation_prefix := ""

#read/written by StatSystem
var is_exhausted:= false

#inventory
var inventory := Inventory.new()

#equipment
var equipment := Equipment.new()

func _init() -> void:
	# The player starts facing the camera; enemies start facing nowhere.
	facing_dir = Vector2.DOWN
