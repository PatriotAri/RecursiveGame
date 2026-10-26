class_name GearStand

extends Stand

## The armor stand, or with `weapons` set, the weapon stand. Upgrades a piece
## to its next material for gold, and puts learned enchantments into its
## slots for souls. Lists everything of its kind the player has, worn first.
## Rules: PlayerUpgradeSystem.

## Weapons instead of armour.
@export var weapons := false
## Souls per enchantment, added or replaced.
@export var enchant_cost := 1
@export var upgrade_sound: SoundEffect
@export var enchant_sound: SoundEffect

## Which of the selected item's slots the enchantment buttons fill. -1 means
## the first empty one, or the first if all are full.
var _slot := -1

func list_rows(player: Node, selected: Variant) -> Array[StandRow]:
	var rows: Array[StandRow] = []
	for item in _gear(player):
		var text: String = item.display_name
		if player.data.equipment.is_equipped(item):
			text += "   (in hand)" if weapons else "   (worn)"
		var row := StandRow.make(text, _select.bind(item))
		row.icon = item.icon
		row.icon_material = MaterialRecolor.for_item(item)
		row.selected = item == selected
		rows.append(row)
	return rows

func empty_text() -> String:
	return "No weapons to work on." if weapons else "No armour to work on. The vendor sells a leather set."

func detail(player: Node, selected: Variant) -> StandDetail:
	var item := selected as EquippableItem
	if item == null or player.data.inventory.get_count(item.id) <= 0: return null
	var data: PlayerData = player.data
	var upgrades: PlayerUpgradeSystem = player.player_upgrade_system
	var info := StandDetail.new()
	info.title = item.display_name
	info.icon = item.icon
	info.icon_material = MaterialRecolor.for_item(item)
	info.text = item.details()
	# Material.
	if item.has_materials():
		var next := item.next_tier()
		var row: StandRow
		if next == null:
			row = StandRow.make("Fully upgraded")
			row.note = upgrades.upgrade_block_reason(data, item)
		else:
			var cost := next.material.upgrade_cost
			row = StandRow.make("Upgrade to %s (%s)   %dg" % [next.material.display_name.to_lower(),
				_stat_text(item, next), cost], _upgrade.bind(player, item))
			row.note = upgrades.upgrade_block_reason(data, item)
			if row.note == "" and count_of(player, gold_item) < cost:
				row.note = "Not enough gold."
			row.disabled = row.note != ""
		info.rows.append(row)
	# Enchantment slots, then what can go in the chosen one.
	var slot := _chosen_slot(item)
	for i in item.slot_count():
		var current: Enchantment = item.added_enchantments[i] if i < item.added_enchantments.size() else null
		var row := StandRow.make("Slot %d: %s" % [i + 1, current.describe() if current else "empty"],
			_choose_slot.bind(item, i))
		row.selected = i == slot
		info.rows.append(row)
	if data.known_enchantments.is_empty():
		var none := StandRow.make("No enchantments learned yet.")
		none.note = "Scrolls teach them. The vendor sells some."
		info.rows.append(none)
	for enchantment in data.known_enchantments:
		var row := StandRow.make("Enchant slot %d: %s   %d soul%s" % [slot + 1, enchantment.describe(),
			enchant_cost, "" if enchant_cost == 1 else "s"], _enchant.bind(player, item, enchantment, slot))
		row.note = upgrades.enchant_block_reason(data, item, enchantment, slot)
		if row.note == "" and count_of(player, soul_item) < enchant_cost:
			row.note = "Not enough souls."
		row.disabled = row.note != ""
		info.rows.append(row)
	return info

## Everything of this stand's kind the player has: worn first, then by name.
func _gear(player: Node) -> Array[EquippableItem]:
	var result: Array[EquippableItem] = []
	for stack in player.data.inventory.get_stacks():
		var item := stack.item as EquippableItem
		if item == null or (item.slot == EquippableItem.Slot.WEAPON) != weapons: continue
		if not item.has_materials() and item.slot_count() <= 0: continue
		result.append(item)
	var equipment: Equipment = player.data.equipment
	result.sort_custom(func(a: EquippableItem, b: EquippableItem) -> bool:
		if equipment.is_equipped(a) != equipment.is_equipped(b):
			return equipment.is_equipped(a)
		return a.display_name < b.display_name)
	return result

## "+1 armour" or "+3 damage": what the next material adds.
func _stat_text(item: EquippableItem, next: ItemTier) -> String:
	if weapons:
		return "%s damage" % String.num(next.damage)
	return "%d armour" % next.armor

func _chosen_slot(item: EquippableItem) -> int:
	if _slot >= 0 and _slot < item.slot_count():
		return _slot
	return mini(item.added_enchantments.size(), item.slot_count() - 1)

func _select(item: EquippableItem) -> Variant:
	_slot = -1
	return item

func _choose_slot(item: EquippableItem, index: int) -> Variant:
	_slot = index
	return item

func _upgrade(player: Node, item: EquippableItem) -> Variant:
	var upgraded: EquippableItem = player.player_upgrade_system.upgrade_material(player.data, item, gold_item)
	if upgraded:
		Sfx.play(upgrade_sound)
	return upgraded

func _enchant(player: Node, item: EquippableItem, enchantment: Enchantment, slot: int) -> Variant:
	var enchanted: EquippableItem = player.player_upgrade_system.enchant(player.data, item, enchantment, slot,
		soul_item, enchant_cost)
	if enchanted:
		Sfx.play(enchant_sound)
	return enchanted
