class_name HealthUtility

var data

func _init(data_ref) -> void:
	data = data_ref

func health_empty() -> bool:
	return data.current_health <= 0

func health_full() -> bool:
	return data.current_health >= data.max_health

func add_health(amount: int) -> void:
	if health_full(): 
		data.current_health = data.max_health
	elif data.current_health + amount >= data.max_health:
		data.current_health = data.max_health
	else:
		data.current_health += amount

func regen_health(amount: int) -> void:
	if health_full():
		return
	elif data.current_health + amount >= data.max_health:
		data.current_health = data.max_health
	else:
		data.current_health += amount

func regen_to_max_health() -> void:
	if health_full():
		return
	else:
		regen_health(data.health_regen_points)
		regen_to_max_health()

func fill_health() -> void:
	if health_full():
		return
	else:
		data.current_health = data.max_health

func remove_health(amount: int) -> void:
	if health_empty():
		data.current_health = 0
	elif data.current_health - amount <= 0:
		data.current_health = 0
	else:
		data.current_health -= amount

func degen_health(amount: int) -> void:
	if health_empty():
		return
	elif data.current_health - amount <= 0:
		data.current_health = 0
	else:
		data.current_health -= amount

func degen_to_min_health(amount) -> void:
	if health_empty():
		return
	else:
		degen_health(amount)
		degen_to_min_health(amount)

func empty_health() -> void:
	if health_empty():
		return
	else:
		data.current_health = 0
