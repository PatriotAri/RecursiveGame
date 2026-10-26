class_name PlayerEquipmentSystem

## Which LayeredSprite layer each armour overlay draws on.
const OVERLAY_LAYERS := {
	EquippableItem.BodyLayer.HEAD: &"Helmet",
	EquippableItem.BodyLayer.TORSO: &"TorsoArmor",
	EquippableItem.BodyLayer.LEFT_ARM: &"LeftArmArmor",
	EquippableItem.BodyLayer.RIGHT_ARM: &"RightArmArmor",
	EquippableItem.BodyLayer.LEGS: &"LegsArmor",
}

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
	_refresh_weapon(data)
	_refresh_armor_visuals(data)
	player.apply_stat_bonuses(StatBonuses.stat_total(data.equipment.get_bonuses()))
	# A swing in flight belongs to the weapon you were holding a moment ago.
	# Without this, post_update() would spawn the NEW weapon's hitbox on the
	# OLD weapon's timer.
	player.player_attack_system.cancel(data)
	player.player_hitbox_manager.cancel_all()

func _refresh_weapon(data: PlayerData) -> void:
	var weapon: EquippableItem = data.equipment.get_item(EquippableItem.Slot.WEAPON)
	if weapon == null:
		_set_unarmed(data)
		return
	if weapon.attack == null:
		push_warning("%s is in the weapon slot but has no attack assigned." % weapon.id)
		_set_unarmed(data)
		return
	# Registering under the item's own id means re-equipping the same weapon
	# overwrites its entry rather than adding another.
	player.player_hitbox_manager.register_attack(weapon.id, weapon.attack)
	data.current_attack = weapon.id
	data.animation_prefix = weapon.animation_prefix
	player.player_weapon_visual_system.set_weapon(weapon)

## Every overlay layer is redrawn, covered or not, so taking a piece off
## clears its layers instead of leaving the last item's art behind.
func _refresh_armor_visuals(data: PlayerData) -> void:
	var worn := {}
	for slot in EquippableItem.Slot.values():
		var item: EquippableItem = data.equipment.get_item(slot)
		if item == null: continue
		for body_layer in item.overlays:
			worn[body_layer] = item.overlays[body_layer]
	for body_layer in OVERLAY_LAYERS:
		player.visual.set_layer_frames(OVERLAY_LAYERS[body_layer], worn.get(body_layer))

## Both values are set together everywhere, so the animation can never end up
## describing a weapon you aren't actually swinging.
func _set_unarmed(data: PlayerData) -> void:
	data.current_attack = &"unarmed"
	data.animation_prefix = ""
	player.player_weapon_visual_system.set_weapon(null)
