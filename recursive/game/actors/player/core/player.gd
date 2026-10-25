class_name Player

extends Actor

## After equipment changes the armor total, for the HUD.
signal armor_changed(armor: int)

var data: PlayerData

var player_input_system: PlayerInputSystem
var player_state_machine: PlayerStateMachine
var player_attack_system: PlayerAttackSystem
var player_movement_system: PlayerMovementSystem
var player_consumable_system: PlayerConsumableSystem
var player_equipment_system: PlayerEquipmentSystem
var player_spell_system: PlayerSpellSystem
var player_interaction_system: PlayerInteractionSystem
var player_animation_system: PlayerAnimationSystem
var player_weapon_visual_system: PlayerWeaponVisualSystem
var player_cost_system: PlayerCostSystem

var player_hitbox_manager: HitboxManagerBase

## Equipment recomputes from these, so the exports stay the unmodified base
## no matter what's worn.
var _base_max_health: int
var _base_max_stamina: int
var _base_max_mana: int
var _base_armor: int
var _base_walk_speed: float
var _base_run_speed: float
var _base_sprint_stamina_cost: float

@onready var camera: CameraRig = $tempcam

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
@export var exhaustion_recovery_ratio: float = 0.25

@export_group("Armor")
## Armor points before equipment.
@export var armor: int = 0

@export_group("Mana")
@export var max_mana: int = 10
@export var mana_regen_per_second: float = 1.0
@export var mana_regen_delay: float = 1.0

@export_category("Combat/Movement")
@export_group("Attack")
## The punch thrown with no weapon equipped. Weapons bring their own.
@export var unarmed_attack: AttackSpec

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
	_base_armor = armor
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
	stats.armor = armor
	_setup_actor(data)
	
	player_hitbox_manager = HitboxManagerBase.new(self, HitboxManagerBase.LAYER_ENEMY_HURTBOX, func(): return data.facing_dir)
	player_hitbox_manager.register_attack(&"unarmed", unarmed_attack)
	
	player_input_system = PlayerInputSystem.new()
	player_state_machine = PlayerStateMachine.new()
	player_attack_system = PlayerAttackSystem.new(self, player_hitbox_manager)
	player_movement_system = PlayerMovementSystem.new(self)
	player_consumable_system = PlayerConsumableSystem.new(self)
	player_weapon_visual_system = PlayerWeaponVisualSystem.new($Sprite/Weapon)
	player_spell_system = PlayerSpellSystem.new(self)
	player_interaction_system = PlayerInteractionSystem.new(self)
	player_equipment_system = PlayerEquipmentSystem.new(self)
	player_animation_system = PlayerAnimationSystem.new(sprite)
	player_cost_system = PlayerCostSystem.new(self)

func _actor_process(delta: float) -> void:
	player_input_system.update(data)
	player_spell_system.update(data, delta)
	player_interaction_system.update(data)
	player_cost_system.update(data, delta)
	
	if data.move_vector != Vector2.ZERO:
		var current_angle := data.facing_dir.angle()
		var target_angle := data.move_vector.angle()
		var t := 1.0 - exp(-data.turn_speed * delta)
		var new_angle := lerp_angle(current_angle, target_angle, t)
		data.facing_dir = Vector2.from_angle(new_angle)
	
	var was_attacking := data.is_attacking
	player_attack_system.update(data, delta)
	if not was_attacking and data.is_attacking:
		var spec := player_hitbox_manager.get_spec(data.active_attack)
		if spec:
			player_cost_system.charge(spec)
			play_sound(spec.sound)
		player_spell_system.on_attack_started(data.active_attack)
	elif was_attacking and not data.is_attacking:
		player_cost_system.on_attack_finished(data)
	player_state_machine.update(data)
	player_attack_system.post_update(data)
	player_movement_system.update(data, delta)
	player_animation_system.update(data, player_attack_system.attack_duration)
	player_weapon_visual_system.update(data, player_attack_system.swing_progress())
	
## Recomputes every equipment-affected value from base + the supplied total.
## Called whenever equipment changes; safe to call with an empty StatBonuses
## to strip all bonuses.
func apply_stat_bonuses(bonuses: StatBonuses) -> void:
	# keep_ratio false: gear gives headroom, it doesn't heal. Taking armour
	# off clamps current down if it's now above the new maximum.
	stats.health.set_maximum(_base_max_health + bonuses.max_health)
	stats.stamina.set_maximum(_base_max_stamina + bonuses.max_stamina)
	stats.mana.set_maximum(_base_max_mana + bonuses.max_mana)
	stats.armor = _base_armor + bonuses.armor
	armor_changed.emit(stats.armor)
	
	data.walk_speed = _base_walk_speed + bonuses.walk_speed
	data.run_speed = _base_run_speed + bonuses.run_speed
	
	# Clamped at zero: free is a legitimate outcome for a very good item,
	# negative is not.
	data.sprint_stamina_cost = maxf(_base_sprint_stamina_cost + bonuses.sprint_stamina_cost, 0.0)
	data.attack_stamina_modifier = bonuses.attack_stamina_cost

## Every hit jolts the camera, staggering or not.
func _on_hit(_dealt: int) -> void:
	camera.shake(3.0, 0.15)

## An interrupted swing takes its hitbox with it.
func _on_staggered() -> void:
	player_attack_system.cancel(data)
	player_hitbox_manager.cancel_all()

# --- save / load ------------------------------------------------------------

## Everything about the player a save needs, as plain JSON-friendly values.
## Items are stored by id; ItemDatabase turns them back into resources.
func to_save_data() -> Dictionary:
	var inventory := []
	for stack in data.inventory.get_stacks():
		inventory.append({"id": String(stack.item.id), "count": stack.count})
	var equipment := {}
	for slot_name in EquippableItem.Slot.keys():
		var item := data.equipment.get_item(EquippableItem.Slot[slot_name])
		if item: equipment[slot_name] = String(item.id)
	return {
		"position": [global_position.x, global_position.y],
		"health": stats.health.current,
		"stamina": stats.stamina.current,
		"mana": stats.mana.current,
		"inventory": inventory,
		"equipment": equipment,
	}

## Restores to_save_data()'s output. Order matters: items first (you can only
## equip what you hold), then equipment (it changes the stat maximums), then
## current stat values, which are clamped to those maximums.
func apply_save_data(save: Dictionary, items: ItemDatabase) -> void:
	for entry in save.get("inventory", []):
		var item := items.find(StringName(entry.get("id", "")))
		if item == null:
			push_warning("Save has unknown item '%s'; skipped." % entry.get("id"))
			continue
		data.inventory.add(item, int(entry.get("count", 1)))
	var equipment: Dictionary = save.get("equipment", {})
	for slot_name in equipment:
		var item := items.find(StringName(equipment[slot_name])) as EquippableItem
		if item: player_equipment_system.try_equip(data, item)
	if save.has("position"):
		var pos: Array = save["position"]
		global_position = Vector2(pos[0], pos[1])
	for stat_name in ["health", "stamina", "mana"]:
		if save.has(stat_name):
			stats.get(stat_name).set_current(int(save[stat_name]))

## Interactables call these as the player walks into and out of reach.
func register_interactable(interactable: Interactable) -> void:
	player_interaction_system.register(interactable)

func unregister_interactable(interactable: Interactable) -> void:
	player_interaction_system.unregister(interactable)

func _handle_death() -> void:
	super()
	player_state_machine.update(data)
	player_animation_system.update(data)
	await sprite.animation_finished
	await get_tree().create_timer(1.0).timeout
	var death_screen := get_tree().get_first_node_in_group(&"death_screen")
	if death_screen == null:
		push_warning("Player died with no death screen in the tree.")
		return
	death_screen.show_death()
