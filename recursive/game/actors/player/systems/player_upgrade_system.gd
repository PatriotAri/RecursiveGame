class_name PlayerUpgradeSystem

## Everything bought at the airship stands, except spell research (see
## PlayerSpellSystem): material upgrades and enchantments at the armor and
## weapon stands, scrolls that teach enchantments, and stat upgrades at the
## soul stand. The stands are menus over this; the rules live here.
##
## An original item is one shared resource, so upgrading or enchanting one
## first swaps it for a copy with its own state (EquippableItem.make_copy()),
## under a new id like "leather_cap#3". The copy takes the original's place
## in the inventory, and in the hands or on the body if it was there.

## Emitted after an item is upgraded or enchanted, with the item as it now is.
signal item_changed(item: EquippableItem)
## A scroll taught an enchantment.
signal enchantments_changed

const ARMOR_SLOTS := [EquippableItem.Slot.HELMET, EquippableItem.Slot.TORSO,
	EquippableItem.Slot.ARMS, EquippableItem.Slot.LEGS]

var player: CharacterBody2D

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref

# --- scrolls ---------------------------------------------------------------

## Teaches the scroll's enchantment and uses up the scroll. Refused, keeping
## the scroll, if it's already known.
func learn(data: PlayerData, scroll: ScrollItem) -> bool:
	if scroll == null or scroll.enchantment == null or data.is_dead: return false
	if knows(data, scroll.enchantment) or data.inventory.get_count(scroll.id) <= 0:
		Sfx.play(Sfx.refused)
		return false
	if not data.inventory.remove(scroll.id, 1): return false
	data.known_enchantments.append(scroll.enchantment)
	Sfx.play(scroll.use_sound)
	enchantments_changed.emit()
	return true

func knows(data: PlayerData, enchantment: Enchantment) -> bool:
	return data.known_enchantments.any(func(known: Enchantment) -> bool: return known.id == enchantment.id)

# --- materials -------------------------------------------------------------

## Why `item` can't move up to its next material, or "" if it can. Gold isn't
## checked here: the stand shows the price either way.
##
## Armour follows the set rule: all four slots must be worn, and no piece,
## worn or spare, can go more than one material above the weakest worn one.
func upgrade_block_reason(data: PlayerData, item: EquippableItem) -> String:
	if not item.has_materials():
		return "%s can't be upgraded." % item.display_name
	var next := item.next_tier()
	if next == null:
		return "%s is %s, the best there is." % [item.display_name, item.current_tier().material.display_name.to_lower()]
	if item.slot == EquippableItem.Slot.WEAPON:
		return ""
	var weakest: EquippableItem = null
	for slot in ARMOR_SLOTS:
		var worn: EquippableItem = data.equipment.get_item(slot)
		if worn == null:
			return "Wear a full set of armour first: helmet, torso, arms and legs."
		if not worn.has_materials(): continue
		if weakest == null or worn.current_tier().material.rank < weakest.current_tier().material.rank:
			weakest = worn
	if weakest and weakest.next_tier() and next.material.rank > weakest.current_tier().material.rank + 1:
		return "Upgrade your %s to %s first." % [weakest.display_name, weakest.next_tier().material.display_name.to_lower()]
	return ""

## Moves `item` up a material for its price in `gold`. Returns the item as it
## now is (a copy, if it was an original), or null if refused.
func upgrade_material(data: PlayerData, item: EquippableItem, gold: Item) -> EquippableItem:
	if data.is_dead or upgrade_block_reason(data, item) != "" \
			or not _pay(data, gold, item.next_tier().material.upgrade_cost):
		Sfx.play(Sfx.refused)
		return null
	var own := _own_copy(data, item)
	own.set_tier(own.tier + 1)
	_changed(data, own)
	return own

# --- enchanting ------------------------------------------------------------

## Why `enchantment` can't go into slot `slot_index` of `item`, or "" if it
## can. A slot past the filled ones means the next empty slot. Souls aren't
## checked here.
func enchant_block_reason(data: PlayerData, item: EquippableItem, enchantment: Enchantment, slot_index: int) -> String:
	if not knows(data, enchantment):
		return "You haven't learned that enchantment."
	if slot_index < 0 or slot_index >= item.slot_count():
		return "%s has no slot for it." % item.display_name
	if item.added_enchantments.any(func(added: Enchantment) -> bool: return added.id == enchantment.id):
		return "%s already has it." % item.display_name
	return ""

## Puts `enchantment` into slot `slot_index` of `item` for `cost` souls,
## replacing whatever was there. Returns the item as it now is, or null if
## refused.
func enchant(data: PlayerData, item: EquippableItem, enchantment: Enchantment, slot_index: int,
		souls: Item, cost: int) -> EquippableItem:
	if data.is_dead or enchant_block_reason(data, item, enchantment, slot_index) != "" \
			or not _pay(data, souls, cost):
		Sfx.play(Sfx.refused)
		return null
	var own := _own_copy(data, item)
	if slot_index < own.added_enchantments.size():
		own.added_enchantments[slot_index] = enchantment
	else:
		own.added_enchantments.append(enchantment)
	_changed(data, own)
	return own

# --- soul stand ------------------------------------------------------------

func purchases(data: PlayerData, upgrade: SoulUpgrade) -> int:
	return int(data.soul_purchases.get(upgrade.id, 0))

## What the next purchase of `upgrade` costs, or -1 once it's bought out.
func next_soul_cost(data: PlayerData, upgrade: SoulUpgrade) -> int:
	var bought := purchases(data, upgrade)
	return upgrade.cost_of(bought) if bought < upgrade.max_purchases else -1

## Buys one step of `upgrade` with souls. Like gear, it raises the maximum
## without filling the new room.
func buy(data: PlayerData, upgrade: SoulUpgrade, souls: Item) -> bool:
	var cost := next_soul_cost(data, upgrade)
	if data.is_dead or cost < 0 or not _pay(data, souls, cost):
		Sfx.play(Sfx.refused)
		return false
	data.soul_purchases[upgrade.id] = purchases(data, upgrade) + 1
	_add_soul_bonus(data, upgrade.stat, upgrade.amount)
	player.player_equipment_system.refresh(data)
	return true

func _add_soul_bonus(data: PlayerData, stat: SoulUpgrade.Stat, amount: int) -> void:
	match stat:
		SoulUpgrade.Stat.MAX_HEALTH: data.soul_bonuses.max_health += amount
		SoulUpgrade.Stat.MAX_STAMINA: data.soul_bonuses.max_stamina += amount
		SoulUpgrade.Stat.MAX_MANA: data.soul_bonuses.max_mana += amount

# --- saves -----------------------------------------------------------------

## Copies are saved as the original they came from plus their own state, and
## rebuilt from it; learned enchantments by id.
func get_save_data(data: PlayerData) -> Dictionary:
	var copies := []
	for stack in data.inventory.get_stacks():
		var item := stack.item as EquippableItem
		if item == null or not item.is_copy(): continue
		copies.append({
			"id": String(item.id),
			"base": String(item.base_id),
			"tier": item.tier,
			"enchantments": item.added_enchantments.map(func(e: Enchantment) -> String: return String(e.id)),
		})
	return {
		"copies": copies,
		"known_enchantments": data.known_enchantments.map(func(e: Enchantment) -> String: return String(e.id)),
		"soul_purchases": data.soul_purchases.duplicate(),
		"soul_bonuses": {
			"max_health": data.soul_bonuses.max_health,
			"max_stamina": data.soul_bonuses.max_stamina,
			"max_mana": data.soul_bonuses.max_mana,
		},
	}

## Restores learned enchantments and soul upgrades, and rebuilds the copies.
## Returns the copies by id, for the inventory to take. Unknown ids are
## skipped with a warning, like unknown items.
func load_save_data(data: PlayerData, saved: Dictionary) -> Dictionary:
	for id in saved.get("known_enchantments", []):
		var enchantment := ContentRegistry.get_enchantment(StringName(id))
		if enchantment == null:
			push_warning("Save has an unknown enchantment '%s'; skipped." % id)
		elif not knows(data, enchantment):
			data.known_enchantments.append(enchantment)
	for id in saved.get("soul_purchases", {}):
		data.soul_purchases[StringName(id)] = int(saved["soul_purchases"][id])
	var bonuses: Dictionary = saved.get("soul_bonuses", {})
	data.soul_bonuses.max_health = int(bonuses.get("max_health", 0))
	data.soul_bonuses.max_stamina = int(bonuses.get("max_stamina", 0))
	data.soul_bonuses.max_mana = int(bonuses.get("max_mana", 0))
	var copies := {}
	for entry in saved.get("copies", []):
		var base := ContentRegistry.get_item(StringName(entry["base"])) as EquippableItem
		if base == null:
			push_warning("Save has a copy of an unknown item '%s'; skipped." % entry["base"])
			continue
		var copy := base.make_copy(StringName(entry["id"]))
		if copy.has_materials():
			copy.set_tier(int(entry["tier"]))
		for id in entry["enchantments"]:
			var enchantment := ContentRegistry.get_enchantment(StringName(id))
			if enchantment and copy.added_enchantments.size() < copy.slot_count():
				copy.added_enchantments.append(enchantment)
		copies[copy.id] = copy
		data.next_copy_number = maxi(data.next_copy_number, _copy_number(copy.id) + 1)
	return copies

# --- helpers ---------------------------------------------------------------

## Spends `amount` of `currency`. Free costs nothing and always succeeds.
func _pay(data: PlayerData, currency: Item, amount: int) -> bool:
	return amount <= 0 or data.inventory.remove(currency.id, amount)

## `item` itself if it's already a copy; otherwise a new copy that takes one
## original's place: in the inventory, and in its slot or as the stowed
## weapon if that's where the original was.
func _own_copy(data: PlayerData, item: EquippableItem) -> EquippableItem:
	if item.is_copy(): return item
	var copy := item.make_copy(StringName("%s#%d" % [item.id, data.next_copy_number]))
	data.next_copy_number += 1
	var was_worn := data.equipment.get_item(item.slot) == item
	data.inventory.remove(item.id, 1)
	data.inventory.add(copy, 1)
	if was_worn:
		data.equipment.equip(copy)
	if data.stowed_weapon == item:
		data.stowed_weapon = copy
	return copy

## Tells everything showing `item` that it changed, and re-applies gear if
## it's worn.
func _changed(data: PlayerData, item: EquippableItem) -> void:
	data.inventory.notify_changed(item)
	if data.equipment.is_equipped(item):
		player.player_equipment_system.refresh(data)
	item_changed.emit(item)

## The number after the "#" in a copy's id.
func _copy_number(copy_id: StringName) -> int:
	var text := String(copy_id)
	var at := text.rfind("#")
	return int(text.substr(at + 1)) if at >= 0 else 0
