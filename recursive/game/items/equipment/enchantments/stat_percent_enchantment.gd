class_name StatPercentEnchantment

extends Enchantment

## A percentage on a stat equipment already changes, applied after the flat
## bonuses: +100% run speed doubles base plus gear.

enum Stat {MAX_HEALTH, MAX_STAMINA, MAX_MANA, WALK_SPEED, RUN_SPEED} #always append enum, never insert in middle

const STAT_NAMES := {
	Stat.MAX_HEALTH: "max health",
	Stat.MAX_STAMINA: "max stamina",
	Stat.MAX_MANA: "max mana",
	Stat.WALK_SPEED: "walk speed",
	Stat.RUN_SPEED: "run speed",
}

@export var stat := Stat.RUN_SPEED
@export var percent := 100.0

func apply_to(totals: EnchantmentTotals) -> void:
	totals.stat_percent[stat] = totals.stat_percent.get(stat, 0.0) + percent

func describe() -> String:
	return "%+d%% %s" % [roundi(percent), STAT_NAMES[stat]]
