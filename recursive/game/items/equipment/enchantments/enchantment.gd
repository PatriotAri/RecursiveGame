class_name Enchantment

extends Resource

## One piece of magic on an item: +15% fire damage, +100% run speed. An item
## carries a list of them; any at all makes it enchanted. Each kind is a
## subclass that adds itself into the totals for everything worn.

## Stable, like an item id: saves refer to learned and added enchantments by
## it. Learnable ones come from scrolls. Empty on built-in ones, which come
## with their item.
@export var id: StringName

func apply_to(_totals: EnchantmentTotals) -> void:
	pass

## One line for item details, e.g. "+15% fire damage".
func describe() -> String:
	return ""
