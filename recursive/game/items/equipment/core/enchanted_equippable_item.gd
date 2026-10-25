class_name EnchantedEquippableItem

extends EquippableItem

## An equippable that carries spells. Its normal attack (if any) still comes
## from EquippableItem.attack; the spells are cast separately with
## player_cast while it's worn. Losing the item loses the spells.

@export var spells: Array[Spell] = []
