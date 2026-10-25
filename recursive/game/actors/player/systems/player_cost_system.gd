class_name PlayerCostSystem

## What the player's attacks cost and whether they can pay: stamina (after
## equipment), mana and ammo. Also sprinting's stamina drain and
## exhaustion. player.gd calls in at the right moments; the rules live here.

var player: Player

func _init(player_ref: Player) -> void:
	player = player_ref
	player.stats.stamina.emptied.connect(_on_stamina_emptied)

## Runs each frame before the attack system sees this frame's requests.
func update(data: PlayerData, delta: float) -> void:
	var stats := player.stats
	if data.is_exhausted and stats.stamina.ratio() >= player.exhaustion_recovery_ratio:
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
	if not data.is_attacking:
		if data.attack_requested and not can_afford(data.current_attack):
			data.attack_requested = false
		if data.cast_requested and not can_afford(data.current_spell_attack):
			data.cast_requested = false

## What one use of an attack costs in stamina, after equipment. Computed per
## swing rather than stored, because it depends on which weapon is equipped.
func stamina_cost_of(spec: AttackSpec) -> int:
	if spec == null: return 0
	return maxi(spec.attack_stamina_cost + player.data.attack_stamina_modifier, 0)

## Stamina, mana and, for attacks that use it, ammo.
func can_afford(attack_name: StringName) -> bool:
	var spec := player.player_hitbox_manager.get_spec(attack_name)
	if spec == null: return false
	if not player.stats.stamina.can_afford(stamina_cost_of(spec)):
		return false
	if not player.stats.mana.can_afford(spec.mana_cost):
		return false
	if spec.ammo_id != &"":
		return player.data.inventory.get_count(spec.ammo_id) >= spec.ammo_cost
	return true

## Takes payment, on the frame an attack actually starts.
func charge(spec: AttackSpec) -> void:
	player.stats.stamina.remove(stamina_cost_of(spec))
	player.stats.mana.remove(spec.mana_cost)
	if spec.ammo_id != &"":
		player.data.inventory.remove(spec.ammo_id, spec.ammo_cost)

## A weapon that is its own ammo (throwing daggers) is gone from the
## inventory after the last throw. Called once the throw finishes:
## unequipping cancels in-flight swings, which would take the last dagger's
## projectile with it mid-windup.
func on_attack_finished(data: PlayerData) -> void:
	var weapon: EquippableItem = data.equipment.get_item(EquippableItem.Slot.WEAPON)
	if weapon == null: return
	if data.inventory.get_count(weapon.id) > 0: return
	player.player_equipment_system.try_unequip(data, EquippableItem.Slot.WEAPON)

func _on_stamina_emptied() -> void:
	player.data.is_exhausted = true
