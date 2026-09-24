class_name PlayerEquipmentSystem

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref

func can_equip(data: PlayerData, item: EquippableItem) -> bool:
	if item == null: return false
	if data.is_dead: return false
	# You can't wear what you don't have.
	if data.inventory.get_count(item.id) <= 0: return false
	return true

func try_equip(data: PlayerData, item: EquippableItem) -> bool:
	if not can_equip(data, item): return false
	if data.equipment.get_item(item.slot) == item: return false
	
	data.equipment.equip(item)
	_refresh(data)
	return true

func try_unequip(data: PlayerData, slot: EquippableItem.Slot) -> bool:
	if data.equipment.get_item(slot) == null: return false
	data.equipment.unequip(slot)
	_refresh(data)
	return true

## Rebuilds everything equipment controls, from whatever is currently worn.
## Called after any change rather than patching individual values, for the
## same reason apply_stat_bonuses() recomputes from base: there's no "undo
## the last item" step to get wrong.
func _refresh(data: PlayerData) -> void:
	_refresh_attack(data)
	player.apply_stat_bonuses(StatBonuses.stat_total(data.equipment.get_bonuses()))
	# A swing in flight belongs to the weapon you were holding a moment ago.
	# Without this, post_update() would spawn the NEW weapon's hitbox on the
	# OLD weapon's timer.
	player.player_attack_system.cancel(data)
	player.player_hitbox_manager.cancel_all()

func _refresh_attack(data: PlayerData) -> void:
	var weapon: EquippableItem = data.equipment.get_item(EquippableItem.Slot.WEAPON)
	if weapon == null:
		data.current_attack = &"unarmed"
		return
	if weapon.attack == null:
		push_warning("%s is in the weapon slot but has no attack assigned." % weapon.id)
		data.current_attack = &"unarmed"
		return
	# Registering under the item's own id means re-equipping the same weapon
	# overwrites its entry rather than adding another.
	player.player_hitbox_manager.register_attack(weapon.id, weapon.attack)
	data.current_attack = weapon.id
