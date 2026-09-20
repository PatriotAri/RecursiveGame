class_name StatRestoreEffect

extends ItemEffect

enum Target {HEALTH, STAMINA, MANA} #always append, never insert anything into the beginning or middle of the lsist

@export var target: Target = Target.HEALTH
@export var amount: int = 10

func would_do_anything(_stats: StatSystem) -> bool:
	var stat := _resolve(stats)
	return stat != null and amount > 0 and not stat.is_full()
	
func apply(stats: StatSystem) -> void:
	var stat := _resolve(stats)
	if stat == null: return
	stat.add(amount)
	
func _resolve(stats: StatSystem) -> Stat:
	match Target:
		Target.HEALTH: return stats.health
		Target.STAMINA: return stats.stamina
		Target.MANA: return stats.mana
