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
var player_weapon_visual_system: PlayerWeaponVisualSystem
var player_interaction_system: PlayerInteractionSystem
var player_spell_system: PlayerSpellSystem
var player_upgrade_system: PlayerUpgradeSystem

var player_hitbox_manager: HitboxManagerBase

## Equipment recomputes from these, so the exports stay the unmodified base
## no matter what's worn.
var _base_max_health: int
var _base_max_stamina: int
var _base_max_mana: int
var _base_walk_speed: float
var _base_run_speed: float
var _base_sprint_stamina_cost: float

var _flash_tween : Tween
var death_handled := false

@onready var visual: LayeredSprite = $Visual

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

@export_group("Armour")
## How much of every hit one armour point takes off.
@export var armor_percent_per_point:= 4.0
## The most armour can take off, however much is worn, so weak enemies stay a
## threat to a fully geared player.
@export var max_armor_percent:= 80.0

@export_category("Combat/Movement")
@export_group("Attack")
@export var windup_time:= 0.1
@export var lifetime:= 0.1
@export var damage:= 10.0
@export var unarmed_offsets: HitboxOffsetData

@export_group("Audio")
@export var unarmed_swing_sound: SoundEffect
@export var unarmed_hit_sound: SoundEffect
@export var hurt_sound: SoundEffect
@export var death_sound: SoundEffect
## Played when stamina runs out.
@export var exhausted_sound: SoundEffect
## Played when a spell is readied or put away.
@export var spell_ready_sound: SoundEffect

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
	
	data.walk_speed = walk_speed
	data.run_speed = run_speed
	data.acceleration = acceleration
	data.friction = friction
	data.sprint_stamina_cost = sprint_stamina_cost
	
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
	unarmed.attack_stamina_cost = attack_stamina_cost
	unarmed.swing_sound = unarmed_swing_sound
	unarmed.hit_sound = unarmed_hit_sound
	
	player_hitbox_manager = HitboxManagerBase.new(self, HitboxManagerBase.LAYER_ENEMY_HURTBOX, func(): return data.facing_dir)
	player_hitbox_manager.aim_provider = get_global_mouse_position
	player_hitbox_manager.register_attack(&"unarmed", unarmed)
	
	player_input_system = PlayerInputSystem.new()
	player_state_machine = PlayerStateMachine.new()
	player_attack_system = PlayerAttackSystem.new(self, player_hitbox_manager)
	player_movement_system = PlayerMovementSystem.new(self)
	player_consumable_system = PlayerConsumableSystem.new(self)
	player_weapon_visual_system = PlayerWeaponVisualSystem.new($Visual/Weapon, visual, $Visual/SpellOrb)
	player_spell_system = PlayerSpellSystem.new(self, spell_ready_sound)
	player_equipment_system = PlayerEquipmentSystem.new(self)
	player_upgrade_system = PlayerUpgradeSystem.new(self)
	player_animation_system = PlayerAnimationSystem.new(visual)
	player_interaction_system = PlayerInteractionSystem.new(self)
	
	$Hurtbox._on_damage_received = _on_damage_received
	$Hurtbox.knockback_received.connect(_on_knockback_received)

func _physics_process(delta: float) -> void:
	if data.is_dead:
		if not death_handled:
			death_handled = true
			_handle_death()
		return
	stats.update(delta)
	player_input_system.update(data)
	if data.spell_key_pressed >= 0:
		player_spell_system.press_slot(data, data.spell_key_pressed)
	
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
	if not was_attacking and data.is_attacking:
		stats.stamina.remove(current_attack_stamina_cost())
		stats.mana.remove(current_attack_mana_cost())
	# Every attack aims at the cursor: facing snaps to it when the attack
	# starts and follows it until the attack ends, then goes back to following
	# movement. Done before anything spawns or animates the attack.
	if data.is_attacking:
		_face_cursor()
	player_state_machine.update(data)
	player_attack_system.post_update(data)
	player_movement_system.update(data, delta)
	player_animation_system.update(data, player_attack_system.swing_progress())
	player_weapon_visual_system.update(data, player_attack_system.swing_progress())
	player_interaction_system.update(data)
	
func _face_cursor() -> void:
	var to_cursor:= get_global_mouse_position() - global_position
	if to_cursor.length() > 1.0:
		data.facing_dir = to_cursor.normalized()

## Recomputes every equipment-affected value from base + the supplied totals:
## flat bonuses first, then enchantment percentages on top. Called whenever
## equipment changes; safe to call with an empty StatBonuses to strip all
## bonuses.
func apply_stat_bonuses(bonuses: StatBonuses, totals: EnchantmentTotals = null) -> void:
	if totals == null:
		totals = EnchantmentTotals.new()
	# keep_ratio false: gear gives headroom, it doesn't heal. Taking armour
	# off clamps current down if it's now above the new maximum.
	stats.health.set_maximum(roundi((_base_max_health + bonuses.max_health) * totals.stat_scale(StatPercentEnchantment.Stat.MAX_HEALTH)))
	stats.stamina.set_maximum(roundi((_base_max_stamina + bonuses.max_stamina) * totals.stat_scale(StatPercentEnchantment.Stat.MAX_STAMINA)))
	stats.mana.set_maximum(roundi((_base_max_mana + bonuses.max_mana) * totals.stat_scale(StatPercentEnchantment.Stat.MAX_MANA)))
	
	data.walk_speed = (_base_walk_speed + bonuses.walk_speed) * totals.stat_scale(StatPercentEnchantment.Stat.WALK_SPEED)
	data.run_speed = (_base_run_speed + bonuses.run_speed) * totals.stat_scale(StatPercentEnchantment.Stat.RUN_SPEED)
	
	# Clamped at zero: free is a legitimate outcome for a very good item,
	# negative is not.
	data.sprint_stamina_cost = maxf(_base_sprint_stamina_cost + bonuses.sprint_stamina_cost, 0.0)
	data.attack_stamina_modifier = bonuses.attack_stamina_cost
	data.armor = maxi(bonuses.armor, 0)

## What one swing of the current attack costs, after equipment. Computed per
## swing rather than stored, because it depends on which weapon is equipped.
func current_attack_stamina_cost() -> int:
	var spec := player_hitbox_manager.get_spec(data.current_attack)
	if spec == null: return 0
	return maxi(spec.attack_stamina_cost + data.attack_stamina_modifier, 0)

## What the current attack costs in mana: a spell's, after any staff.
func current_attack_mana_cost() -> int:
	var spec := player_hitbox_manager.get_spec(data.current_attack)
	return spec.mana_cost if spec else 0

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
		if not stats.stamina.can_afford(current_attack_stamina_cost()):
			data.attack_requested = false

func _on_stamina_emptied() -> void:
	data.is_exhausted = true
	Sfx.play(exhausted_sound, global_position)

func _on_damage_received(damage_amount: float, apply_hitstun: bool) -> void:
	stats.health.remove(damage_after_armor(damage_amount))
	if data.is_dead:
		return
	Sfx.play(hurt_sound, global_position)
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

## Percent reduction: each armour point takes armor_percent_per_point off
## every hit, up to max_armor_percent. Health keeps the fraction.
func damage_after_armor(damage_amount: float) -> float:
	if damage_amount <= 0.0: return 0.0
	return damage_amount * (1.0 - armor_reduction())

## The share of every hit armour takes off, from 0 to max_armor_percent / 100.
func armor_reduction() -> float:
	return minf(data.armor * armor_percent_per_point, max_armor_percent) / 100.0

func _on_health_emptied() -> void:
	data.is_dead = true

func _on_knockback_received(direction: Vector2, strength: float, decay: float) -> void:
	var knockback := MovementModifier.create_impulse(&"knockback", direction, strength, decay)
	data.modifiers.add(knockback)

## Everything about the player a save keeps: where they stand, their
## current health, stamina and mana, what they carry and what they wear, and
## what they've bought at the stands. Items are stored by id; see
## ContentRegistry. Copies made at the stands are rebuilt from their
## original; see PlayerUpgradeSystem.
func get_save_data() -> Dictionary:
	var items := {}
	for stack in data.inventory.get_stacks():
		items[String(stack.item.id)] = stack.count
	var worn := {}
	for slot in EquippableItem.Slot.values():
		var item: EquippableItem = data.equipment.get_item(slot)
		if item:
			worn[str(slot)] = String(item.id)
	var saved := {
		"position": [global_position.x, global_position.y],
		"health": stats.health.current,
		"stamina": stats.stamina.current,
		"mana": stats.mana.current,
		"inventory": items,
		"equipment": worn,
	}
	saved.merge(player_spell_system.get_save_data(data))
	saved.merge(player_upgrade_system.get_save_data(data))
	return saved

func load_save_data(saved: Dictionary) -> void:
	var copies := player_upgrade_system.load_save_data(data, saved)
	for id in saved.get("inventory", {}):
		var item: Item = copies.get(StringName(id), ContentRegistry.get_item(StringName(id)))
		if item == null:
			push_warning("Save has an unknown item '%s'; skipped." % id)
			continue
		data.inventory.add(item, int(saved["inventory"][id]))
	# Gear goes back on before stats are set, since it changes the maximums.
	for slot in saved.get("equipment", {}):
		var item := resolve_item(StringName(saved["equipment"][slot])) as EquippableItem
		if item:
			player_equipment_system.try_equip(data, item, true)
	# Soul upgrades change the maximums too, worn gear or not.
	player_equipment_system.refresh(data)
	# Before stats too: a readied spell decides the attack, and its staff the
	# maximums.
	player_spell_system.load_save_data(data, saved)
	var position_saved: Array = saved.get("position", [global_position.x, global_position.y])
	global_position = Vector2(position_saved[0], position_saved[1])
	stats.health.current = clampf(float(saved.get("health", stats.health.maximum)), 0.0, stats.health.maximum)
	# A save is only ever made alive; a damaged one doesn't load a corpse.
	if stats.health.current <= 0.0:
		stats.health.current = 1.0
	stats.stamina.current = clampf(float(saved.get("stamina", stats.stamina.maximum)), 0.0, stats.stamina.maximum)
	stats.mana.current = clampf(float(saved.get("mana", stats.mana.maximum)), 0.0, stats.mana.maximum)
	for stat in [stats.health, stats.stamina, stats.mana]:
		stat.changed.emit(stat.current, stat.maximum)

## The item with `id` that the player has, a copy made at a stand included,
## else the original from ContentRegistry. Null for an unknown id.
func resolve_item(id: StringName) -> Item:
	var stack := data.inventory.get_stack(id)
	return stack.item if stack else ContentRegistry.get_item(id)

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
	visual.modulate = Color(1, 0.3, 0.3)
	_flash_tween = create_tween()
	_flash_tween.tween_property(visual, "modulate", Color.WHITE, 0.15)

func _handle_death() -> void:
	Sfx.play(death_sound, global_position)
	$Collision.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitorable", false)
	player_state_machine.update(data)
	player_animation_system.update(data)
	await visual.animation_finished
	await get_tree().create_timer(1.0).timeout
	var death_screen := get_tree().get_first_node_in_group(&"death_screen")
	if death_screen == null:
		push_warning("Player died with no death screen in the tree.")
		return
	death_screen.show_death()
