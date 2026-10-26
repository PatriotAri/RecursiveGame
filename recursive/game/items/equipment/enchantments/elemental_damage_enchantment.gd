class_name ElementalDamageEnchantment

extends Enchantment

## A percentage boost to every attack of one damage type, from any source:
## +15% fire on a staff boosts Fireball, cast from it or not.

@export var damage_type := AttackSpec.DamageType.FIRE
@export var percent := 15.0

func apply_to(totals: EnchantmentTotals) -> void:
	totals.damage_percent[damage_type] = totals.damage_percent.get(damage_type, 0.0) + percent

func describe() -> String:
	var type_name := String(AttackSpec.DamageType.keys()[damage_type]).to_lower()
	return "%+d%% %s damage" % [roundi(percent), type_name]
