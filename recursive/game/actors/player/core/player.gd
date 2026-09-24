extends CharacterBody2D

var data: PlayerData
var stats: StatSystem

var player_input_system: PlayerInputSystem
var player_state_machine: PlayerStateMachine
var player_attack_system: PlayerAttackSystem
var player_movement_system: PlayerMovementSystem
var player_consumable_system: PlayerConsumableSystem
var player_equipment_system: PlayerEquipmentSystem
var player_animation_system: PlayerAnimationSystem

var player_hitbox_manager: HitboxManagerBase

## Equipment recomputes from these, so the exports stay the unmodified base
## no matter what's worn.
var _base_max_health: int
var _base_max_stamina: int
var _base_max_mana: int
var _base_walk_speed: float
var _base_run_speed: float
var _base_sprint_stamina_cost: float
var _base_attack_stamina_cost: int

var _flash_tween : Tween
var death_handled := false

@onready var sprite: AnimatedSprite2D = $Sprite

@export_category("Stat Tuning")
@export_group("Health")
@export var max_health: int = 20
@export var health_regen_per_second: float = 0.0
@export var health_regen_delay: float = 3.0

@export_group("Stamina")
@export var max_stamina: int = 20
@export var stamina_regen_per_second: float = 8.0
@export var stamina_regen_delay: float = 0.5
@export var sprint_stamina_cost: float = 12.0
@export var attack_stamina_cost: int = 4
@export var exhaustion_recovery_ratio: float = 0.25

@export_group("Mana")
@export var max_mana: int = 10
@export var mana_regen_per_second: float = 1.0
@export var mana_regen_delay: float = 1.0

@export_category("Combat/Movement")
@export_group("Attack")
@export var windup_time:= 0.1
@export var lifetime:= 0.1
@export var damage:= 10.0
@export var unarmed_offsets: HitboxOffsetData

@export_group("Combat Feel")
#how long player is locked in hitstun
@export var hurt_duration:= 0.12

@export_group("Movement")
@export var walk_speed:= 100.0
@export var run_speed:= 140.0
@export var acceleration:= 600.0
@export var friction:= 800.0

func _ready() -> void:
	data = PlayerData.new()
	
	_base_max_health = max_health
	_base_max_stamina = max_stamina
	_base_max_mana = max_mana
	_base_walk_speed = walk_speed
	_base_run_speed = run_speed
	_base_sprint_stamina_cost = sprint_stamina_cost
	_base_attack_stamina_cost = attack_stamina_cost
	
	data.walk_speed = walk_speed
	data.run_speed = run_speed
	data.acceleration = acceleration
	data.friction = friction
	data.sprint_stamina_cost = sprint_stamina_cost
	data.attack_stamina_cost = attack_stamina_cost
	
	stats = StatSystem.new(
		Stat.new(max_health, health_regen_per_second, health_regen_delay),
		Stat.new(max_stamina, stamina_regen_per_second, stamina_regen_delay),
		Stat.new(max_mana, mana_regen_per_second, mana_regen_delay)
	)
	stats.health.emptied.connect(_on_health_emptied)
	stats.stamina.emptied.connect(_on_stamina_emptied)
	
	var unarmed := AttackSpec.new()
	unarmed.scene = GlobalPackedScenes.player_unarmed_hitbox
	unarmed.offsets = unarmed_offsets
	unarmed.damage = damage
	unarmed.windup_time = windup_time
	unarmed.lifetime = lifetime
	unarmed.knockback_strength = 50.0
	unarmed.hitstun_chance = 0.3
	unarmed.knockback_chance = 0.3
	
	player_hitbox_manager = HitboxManagerBase.new(self, HitboxManagerBase.LAYER_ENEMY_HURTBOX, func(): return data.facing_dir)
	player_hitbox_manager.register_attack(&"unarmed", unarmed)
	
	player_input_system = PlayerInputSystem.new()
	player_state_machine = PlayerStateMachine.new()
	player_attack_system = PlayerAttackSystem.new(self, player_hitbox_manager)
	player_movement_system = PlayerMovementSystem.new(self)
	player_consumable_system = PlayerConsumableSystem.new(self)
	player_equipment_system = PlayerEquipmentSystem.new(self)
	player_animation_system = PlayerAnimationSystem.new(sprite)
	
	$Hurtbox._on_damage_received = _on_damage_received
	$Hurtbox.knockback_received.connect(_on_knockback_received)

	var test_weapon: EquippableItem = load("res://game/items/equipment/test_weapon.tres")
	data.inventory.add(test_weapon, 1)
	player_equipment_system.try_equip(data, test_weapon)

func _physics_process(delta: float) -> void:
	if data.is_dead:
		if not death_handled:
			death_handled = true
			_handle_death()
		return
	stats.update(delta)
	player_input_system.update(data)
	
	#hitstun is a timer now, ticks before the state machine
	if data.hurt_timer > 0.0:
		data.hurt_timer -= delta
		if data.hurt_timer <= 0.0:
			data.is_hurt = false
	
	_update_stamina(delta)
	
	if data.move_vector != Vector2.ZERO:
		var current_angle := data.facing_dir.angle()
		var target_angle := data.move_vector.angle()
		var t := 1.0 - exp(-data.facing_turn_speed * delta)
		var new_angle := lerp_angle(current_angle, target_angle, t)
		data.facing_dir = Vector2.from_angle(new_angle)
	
	var was_attacking := data.is_attacking
	player_attack_system.update(data, delta)
	if not was_attacking and data.is_attacking: # ← new
		stats.stamina.remove(data.attack_stamina_cost)
	player_state_machine.update(data)
	player_attack_system.post_update(data)
	player_movement_system.update(data, delta)
	player_animation_system.update(data)

## Recomputes every equipment-affected value from base + the supplied total.
## Called whenever equipment changes; safe to call with an empty StatBonuses
## to strip all bonuses.
func apply_stat_bonuses(bonuses: StatBonuses) -> void:
	# keep_ratio false: gear gives headroom, it doesn't heal. Taking armour
	# off clamps current down if it's now above the new maximum.
	stats.health.set_maximum(_base_max_health + bonuses.max_health)
	stats.stamina.set_maximum(_base_max_stamina + bonuses.max_stamina)
	stats.mana.set_maximum(_base_max_mana + bonuses.max_mana)
	
	data.walk_speed = _base_walk_speed + bonuses.walk_speed
	data.run_speed = _base_run_speed + bonuses.run_speed
	
	# Clamped at zero: free is a legitimate outcome for a very good item,
	# negative is not.
	data.sprint_stamina_cost = maxf(_base_sprint_stamina_cost + bonuses.sprint_stamina_cost, 0.0)
	data.attack_stamina_cost = maxi(_base_attack_stamina_cost + bonuses.attack_stamina_cost, 0)

func _update_stamina(delta: float) -> void:
	if data.is_exhausted and stats.stamina.ratio() >= exhaustion_recovery_ratio:
		data.is_exhausted = false

	# Intent alone isn't enough — holding run while standing still costs nothing.
	var sprinting := data.is_running and data.move_vector != Vector2.ZERO
	if data.is_exhausted or (sprinting and stats.stamina.is_empty()):
		data.is_running = false
		sprinting = false
	if sprinting:
		stats.stamina.drain(data.sprint_stamina_cost, delta)

	# Refuse an unaffordable swing before the attack system sees the request,
	# so the input isn't eaten and the animation never plays for free.
	if data.attack_requested and not data.is_attacking:
		if not stats.stamina.can_afford(data.attack_stamina_cost):
			data.attack_requested = false

func _on_stamina_emptied() -> void:
	data.is_exhausted = true

func _on_damage_received(damage_amount: float, apply_hitstun: bool) -> void:
	stats.health.remove(roundi(damage_amount))
	if data.is_dead:
		return
	_flash_damage()
	if not apply_hitstun:
		return
	# Re-arming the timer on every hit is what kills the permanent freeze:
	# the old code waited on an animation_finished that never fires when the
	# hurt state is re-entered without the animation name changing.
	data.is_hurt = true
	data.hurt_timer = hurt_duration
	data.hurt_seq += 1
	# An interrupted swing takes its hitbox with it.
	player_attack_system.cancel(data)
	player_hitbox_manager.cancel_all()

func _on_health_emptied() -> void:
	data.is_dead = true

func _on_knockback_received(direction: Vector2, strength: float, decay: float) -> void:
	var knockback := MovementModifier.create_impulse(&"knockback", direction, strength, decay)
	data.modifiers.add(knockback)

## The point other actors aim at. Movement wants our feet (global_position);
## combat wants the middle of what it has to hit.
func combat_anchor() -> Vector2:
	return $Hurtbox/CollisionShape2D.global_position

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

func _handle_death() -> void:
	$Collision.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitorable", false)
	player_state_machine.update(data)
	player_animation_system.update(data)
	await sprite.animation_finished
	await get_tree().create_timer(1.0).timeout
	var death_screen := get_tree().get_first_node_in_group(&"death_screen")
	if death_screen == null:
		push_warning("Player died with no death screen in the tree.")
		return
	death_screen.show_death()
