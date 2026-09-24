class_name Equipment

## Emitted after any change, so the player can recompute stats and the UI
## can refresh. Mirrors Inventory.changed.
signal equipment_changed

var _slots: Dictionary = {}  # Slot -> EquippableItem

## Puts an item in its slot and returns whatever it displaced, or null if the
## slot was empty. This class only tracks what's worn — the caller decides
## what happens to the displaced item.
func equip(item: EquippableItem) -> EquippableItem:
	if item == null: return null
	var previous: EquippableItem = _slots.get(item.slot)
	if previous == item: return null
	_slots[item.slot] = item
	equipment_changed.emit()
	return previous

func unequip(slot: EquippableItem.Slot) -> EquippableItem:
	var previous: EquippableItem = _slots.get(slot)
	if previous == null: return null
	_slots.erase(slot)
	equipment_changed.emit()
	return previous

func get_item(slot: EquippableItem.Slot) -> EquippableItem:
	return _slots.get(slot)

func is_equipped(item: Item) -> bool:
	for equipped in _slots.values():
		if equipped == item:
			return true
	return false

## Every worn item's bonuses, ready to hand to StatBonuses.total().
func get_bonuses() -> Array[StatBonuses]:
	var result: Array[StatBonuses] = []
	for equipped in _slots.values():
		if equipped.bonuses != null:
			result.append(equipped.bonuses)
	return result
