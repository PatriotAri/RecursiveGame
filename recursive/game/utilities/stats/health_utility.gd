class_name HealthUtility

var data: PlayerData

func _init(data_ref: PlayerData) -> void:
	data = data_ref

func health_empty() -> bool:
	return data.current_health <= 0

func health_full() -> bool:
	return data.current_health >= data.max_health

#used for mana potions, effects, etc.
func add_health(amount: int) -> void:
	if health_full():
		data.current_health = data.max_health
	elif data.current_health + amount >= data.max_health:
		data.current_health = data.max_health
	else:
		data.current_health += amount

func remove_health(amount: int) -> void:
	if health_empty():
		data.current_health = 0
	elif data.current_health - amount <= 0:
		data.current_health = 0
	else:
		data.current_health -= amount

func regen_health(amount: int) -> void:
	if health_full():
		return
	elif data.current_health + amount >= data.max_health:
		data.current_health = data.max_health
	else:
		data.current_health += amount

func regen_max_health() -> void:
	if health_full():
		return
	else:
		regen_health(data.health_regen_points)
		regen_max_health()
