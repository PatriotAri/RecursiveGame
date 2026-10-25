class_name StatSystem

var health: Stat
var stamina: Stat
var mana: Stat

## Armor points. Every hit is scaled by ARMOR_SCALE / (ARMOR_SCALE + armor):
## 10 armor halves damage, 30 quarters it. Diminishing returns, so stacking
## gear always helps but never makes anything immune.
const ARMOR_SCALE := 10.0
var armor: int = 0

## What armor shaved off as a fraction of a point, kept for the next hit.
## Without it, armor would round every 1-damage hit down to nothing.
var _damage_carry: float = 0.0

func _init(health_stat: Stat, stamina_stat: Stat = null, mana_stat: Stat = null) -> void:
	health = health_stat
	stamina = stamina_stat
	mana = mana_stat

## The damage that gets through `armor`, before rounding.
func mitigate(amount: float) -> float:
	return amount * ARMOR_SCALE / (ARMOR_SCALE + maxf(armor, 0))

## Applies a hit to health through armor. Returns the whole points actually
## removed — what a damage number should show. Can be 0 when armor soaked
## this one; the remainder lands on a later hit.
func take_damage(amount: float) -> int:
	if amount <= 0.0: return 0
	_damage_carry += mitigate(amount)
	var whole := int(_damage_carry)
	_damage_carry -= whole
	health.remove(whole)
	return whole

func update(delta: float) -> void:
	health.tick(delta)
	if stamina != null: stamina.tick(delta)
	if mana != null: mana.tick(delta)
