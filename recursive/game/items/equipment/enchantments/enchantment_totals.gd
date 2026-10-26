class_name EnchantmentTotals

## Everything the worn items' enchantments add up to. Built fresh whenever
## equipment changes, the same way StatBonuses.stat_total() is, so there's no
## running total to get out of step.

## Percent bonus per damage type: AttackSpec.DamageType -> float.
var damage_percent := {}
## Percent bonus per stat: StatPercentEnchantment.Stat -> float.
var stat_percent := {}
## Extra enemies a projectile passes through.
var pierce := 0

static func from_items(items: Array) -> EnchantmentTotals:
	var totals := EnchantmentTotals.new()
	for item in items:
		if item == null: continue
		for enchantment in item.enchantments:
			if enchantment: enchantment.apply_to(totals)
	return totals

## What an attack of `type` is multiplied by.
func damage_scale(type: AttackSpec.DamageType) -> float:
	return 1.0 + damage_percent.get(type, 0.0) / 100.0

## What `stat` is multiplied by, after flat bonuses.
func stat_scale(stat: StatPercentEnchantment.Stat) -> float:
	return 1.0 + stat_percent.get(stat, 0.0) / 100.0
