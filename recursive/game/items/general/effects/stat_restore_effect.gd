class_name StatRestoreEffect

extends ItemEffect

enum Target {HEALTH, STAMINA, MANA} #always append, never insert anything into the beginning or middle of the list

@export var target: Target = Target.HEALTH
@export var amount: int = 10

func would_do_anything(stats: StatSystem) -> bool:
	var stat := _resolve(stats)
	# Stat.add() silently no-ops at full, so without this the item is spent
	# for nothing.
	return stat != null and amount > 0 and not stat.is_full()

func apply(stats: StatSystem) -> void:
	var stat := _resolve(stats)
	if stat == null: return
	stat.add(amount)

## StatSystem allows null stamina and mana, so every lookup can miss.
func _resolve(stats: StatSystem) -> Stat:
	if stats == null: return null
	match target:
		Target.HEALTH: return stats.health
		Target.STAMINA: return stats.stamina
		Target.MANA: return stats.mana
	return null
