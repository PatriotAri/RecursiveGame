class_name StatSystem

var health: Stat
var stamina: Stat
var mana: Stat

func _init(health_stat: Stat, stamina_stat: Stat = null, mana_stat: Stat = null) -> void:
	health = health_stat
	stamina = stamina_stat
	mana = mana_stat

func update(delta: float) -> void:
	health.tick(delta)
	if stamina != null: stamina.tick(delta)
	if mana != null: mana.tick(delta)
