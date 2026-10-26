class_name Enemy

extends CharacterBody2D

## Shared base for every enemy type. Owns what all enemies have in common —
## health, the hurtbox, hitstun, knockback, death and drops — and runs the
## behaviour systems each frame. A type changes behaviour by registering its
## attacks in _register_attacks() and, where it needs to, overriding the
## _create_* methods to plug in different systems. Nothing here should need
## copying into a type.

#type casts DetectionArea as DetectionSystem, allows script to send signals
@onready var detection_system: EnemyDetectionSystem = $DetectionArea as EnemyDetectionSystem
@onready var sprite: AnimatedSprite2D = $Sprite
## Pathfinding and crowd avoidance. Optional: without one, the enemy walks
## straight at its targets.
@onready var navigation_agent: NavigationAgent2D = get_node_or_null("NavigationAgent")
var state_machine: EnemyStateMachine
var movement_system: EnemyMovementSystem
var attack_system: EnemyAttackSystem
var animation_system: EnemyAnimationSystem
var hitbox_manager: HitboxManagerBase

#health component
var stats: StatSystem
var _flash_tween: Tween
var death_handled := false

## The registered attack the attack system swings, and the one attack range
## is measured from. A type registers it in _register_attacks().
var primary_attack: StringName = &"melee"

@export_group("Stat Tuning")
@export var max_health: int = 10

@export_group("Combat Tuning")
## How long the enemy is locked in hitstun. Was implicitly the hurt
## animation's length; now independent of it.
@export var hurt_duration:= 0.2
## Pause between swings. Owed after a completed attack and after an
## interrupted one.
@export var attack_cooldown:= 1.5
## Half-width of what this enemy is trying to hit — the player's hurtbox is
## 32 wide, so 16. The narrow axis, so the derived range stays conservative.
@export var target_radius:= 16.0
## Grace period after the player leaves the detection shape before aggro drops.
## Stops a target walking the boundary from flickering CHASE/PATROL every frame.
@export var target_forget_delay:= 1.0
## After losing the player, the enemy heads for where it last saw them. This
## is how long it can go without making headway (stuck in a crowd, say)
## before it gives up and goes back to patrolling.
@export var search_timeout:= 3.0

## Derived in _ready() from the primary attack's own geometry.
var attack_range:= 0.0

#patrol variables
@export_group("Patrol Tuning")
@export var patrol_wait_time:= 3.5
@export var patrol_timer:= 0.0
@export var min_patrol_distance:= 40.0

@export_group("Drop Tuning")
@export var drop_table: DropTable

var data: EnemyData

func _ready() -> void:
	stats = StatSystem.new(Stat.new(max_health))
	stats.health.emptied.connect(_on_health_emptied)

	data = EnemyData.new()

	hitbox_manager = HitboxManagerBase.new(self, HitboxManagerBase.LAYER_PLAYER_HURTBOX, func(): return data.facing_dir)
	_register_attacks()

	# Commit range comes from the hitbox instead of a hand-typed number.
	# Must be computed before the detection system initialises below.
	attack_range = _compute_attack_range()

	$Hurtbox._on_damage_received = _on_damage_received
	$Hurtbox.knockback_received.connect(_on_knockback_received)

	#injects data
	detection_system.initialize(data, self)

	state_machine = _create_state_machine()
	movement_system = _create_movement_system()
	attack_system = _create_attack_system()
	animation_system = _create_animation_system()

func _physics_process(delta: float) -> void:
	if data.is_dead:
		if not death_handled:
			death_handled = true
			_handle_death()
		return

	stats.update(delta)

	# Hitstun is a timer now. Ticked before the state machine so is_hurt is
	# current when the state resolves this frame.
	if data.hurt_timer > 0.0:
		data.hurt_timer -= delta
		if data.hurt_timer <= 0.0:
			data.is_hurt = false

	detection_system.update(delta)
	state_machine.update(data, delta)
	movement_system.update(delta)
	attack_system.update(data, delta)
	animation_system.update()

## Registers this type's attacks with hitbox_manager. Every type overrides it.
func _register_attacks() -> void:
	push_warning("%s registers no attacks." % name)

## How close the target has to be before this enemy commits to an attack:
## the primary attack's shortest reach plus the target's half-width.
func _compute_attack_range() -> float:
	var spec := hitbox_manager.get_spec(primary_attack)
	if spec == null:
		return 0.0
	return spec.min_reach() + target_radius

# The systems each type runs. Override one to give a type different
# behaviour without touching the rest.
func _create_state_machine() -> EnemyStateMachine:
	return EnemyStateMachine.new(attack_cooldown)

func _create_movement_system() -> EnemyMovementSystem:
	return EnemyMovementSystem.new(self, data)

func _create_attack_system() -> EnemyAttackSystem:
	return EnemyAttackSystem.new(self, hitbox_manager)

func _create_animation_system() -> EnemyAnimationSystem:
	return EnemyAnimationSystem.new(sprite, data)

func _on_damage_received(damage_amount: float, apply_hitstun: bool) -> void:
	stats.health.remove(roundi(damage_amount))
	if data.is_dead:
		return
	_flash_damage()
	if not apply_hitstun:
		return
	data.is_hurt = true
	data.hurt_timer = hurt_duration
	data.hurt_seq += 1
	# Getting hit drops the swing — but only when the stagger lands.
	hitbox_manager.cancel_all()

## Feedback that a hit landed, separate from whether it staggered. Every hit
## flashes; only some of them interrupt.
func _flash_damage() -> void:
	# A second hit mid-flash would otherwise leave two tweens fighting over
	# modulate, and the sprite can end up stuck tinted.
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	sprite.modulate = Color(1, 0.3, 0.3)
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func _on_health_emptied() -> void:
	data.is_dead = true

func _on_knockback_received(direction: Vector2, strength: float, decay: float) -> void:
	var knockback := MovementModifier.create_impulse(&"knockback", direction, strength, decay)
	data.modifiers.add(knockback)

func _handle_death() -> void:
	set_physics_process(false)
	# Hitboxes are children with their own _physics_process — killing this
	# node's processing doesn't stop theirs. A swing started before the
	# killing blow would still land from the corpse.
	hitbox_manager.cancel_all()
	# Stop being a wall, and stop eating the player's attacks.
	$Collision.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitorable", false)
	sprite.play("died")
	_try_spawn_drops()
	await sprite.animation_finished
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _try_spawn_drops() -> void:
	if drop_table == null: return
	drop_table.roll(get_parent(), global_position)
