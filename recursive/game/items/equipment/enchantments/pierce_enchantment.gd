class_name PierceEnchantment

extends Enchantment

## Projectiles pass through more enemies before stopping: thrown weapons and
## spells alike.

@export var amount := 1

func apply_to(totals: EnchantmentTotals) -> void:
	totals.pierce += amount

func describe() -> String:
	return "Projectiles pierce %d more %s" % [amount, "enemy" if amount == 1 else "enemies"]
