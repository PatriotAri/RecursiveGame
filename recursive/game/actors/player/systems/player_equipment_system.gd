class_name PlayerEquipmentSystem

## Which LayeredSprite layer each armour overlay draws on.
const OVERLAY_LAYERS := {
	EquippableItem.BodyLayer.HEAD: &"Helmet",
	EquippableItem.BodyLayer.TORSO: &"TorsoArmor",
	EquippableItem.BodyLayer.LEFT_ARM: &"LeftArmArmor",
	EquippableItem.BodyLayer.RIGHT_ARM: &"RightArmArmor",
	EquippableItem.BodyLayer.LEGS: &"LegsArmor",
}

## The animation set every spell is cast with, staff or not.
const CAST_PREFIX := "cast"

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref

func can_equip(data: PlayerData, item: EquippableItem) -> bool:
	if item == null: return false
	if data.is_dead: return false
	# You can't wear what you don't have.
	if data.inventory.get_count(item.id) <= 0: return false
	return true

## `quiet` skips the equip sound, for putting gear back on when a save loads.
func try_equip(data: PlayerData, item: EquippableItem, quiet := false) -> bool:
	if not can_equip(data, item): return false
	if data.equipment.get_item(item.slot) == item: return false
	# Taking up a weapon puts a readied spell away. A staff doesn't: it's what
	# spells are cast through.
	if item.slot == EquippableItem.Slot.WEAPON and data.readied_spell and not item.casting_focus:
		player.player_spell_system.put_away(data, false)
	
	data.equipment.equip(item)
	refresh(data)
	if not quiet:
		Sfx.play(item.equip_sound if item.equip_sound else Sfx.equip)
	return true

func try_unequip(data: PlayerData, slot: EquippableItem.Slot) -> bool:
	if data.equipment.get_item(slot) == null: return false
	data.equipment.unequip(slot)
	refresh(data)
	Sfx.play(Sfx.unequip)
	return true

## Rebuilds everything equipment controls, from whatever is currently worn
## and readied. Called after any change rather than patching individual
## values, for the same reason apply_stat_bonuses() recomputes from base:
## there's no "undo the last item" step to get wrong.
func refresh(data: PlayerData) -> void:
	var totals := EnchantmentTotals.from_items(data.equipment.get_items())
	_refresh_attack(data, totals)
	_refresh_armor_visuals(data)
	player.apply_stat_bonuses(StatBonuses.stat_total(data.equipment.get_bonuses()), totals)
	# A swing in flight belongs to the weapon you were holding a moment ago.
	# Without this, post_update() would spawn the NEW weapon's hitbox on the
	# OLD weapon's timer.
	player.player_attack_system.cancel(data)
	player.player_hitbox_manager.cancel_all()

## What the attack button does: the readied spell (amplified by a held
## staff), else the weapon's own attack, else a punch. Enchantments apply to
## each. What's registered is always a modified copy, never the item's or
## spell's own shared spec.
func _refresh_attack(data: PlayerData, totals: EnchantmentTotals) -> void:
	var weapon: EquippableItem = data.equipment.get_item(EquippableItem.Slot.WEAPON)
	var staff: EquippableItem = weapon if weapon and weapon.casting_focus else null
	var hitboxes: HitboxManagerBase = player.player_hitbox_manager
	player.player_weapon_visual_system.set_weapon(weapon)
	player.player_weapon_visual_system.set_spell(data.readied_spell, staff)
	hitboxes.launch_point_provider = Callable()
	if data.readied_spell:
		var base := data.readied_spell.attack
		var spec := base.modified(
			totals.damage_scale(base.damage_type) * (staff.amplify_damage if staff else 1.0),
			staff.amplify_mana if staff else 1.0,
			staff.amplify_area if staff else 1.0,
			totals.pierce)
		var key := StringName("spell_" + String(data.readied_spell.id))
		hitboxes.register_attack(key, spec)
		# Cast from wherever the spell is shown: between the hands, or the
		# staff's tip.
		hitboxes.launch_point_provider = player.player_weapon_visual_system.spell_point
		data.current_attack = key
		data.animation_prefix = CAST_PREFIX
		return
	if weapon == null:
		_set_unarmed(data)
		return
	if staff:
		# No melee of its own, and no spell readied: nothing to attack with.
		data.current_attack = &""
		data.animation_prefix = staff.animation_prefix
		return
	if weapon.attack == null:
		push_warning("%s is in the weapon slot but has no attack assigned." % weapon.id)
		_set_unarmed(data)
		return
	# Registering under the item's own id means re-equipping the same weapon
	# overwrites its entry rather than adding another.
	hitboxes.register_attack(weapon.id, weapon.attack.modified(
		totals.damage_scale(weapon.attack.damage_type), 1.0, 1.0, totals.pierce))
	data.current_attack = weapon.id
	data.animation_prefix = weapon.animation_prefix

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
