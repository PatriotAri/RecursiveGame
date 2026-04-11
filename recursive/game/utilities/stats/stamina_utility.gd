class_name StaminaUtility

var data: PlayerData

func _init(data_ref: PlayerData) -> void:
	data = data_ref

func stamina_empty() -> bool:
	return data.current_stamina <= 0

func stamina_full() -> bool:
	return data.current_stamina >= data.max_stamina

func add_stamina(amount: int) -> void:
	if stamina_full():
		data.current_stamina = data.max_stamina
	elif data.current_stamina + amount >= data.max_stamina:
		data.current_stamina = data.max_stamina
	else:
		data.current_stamina += amount

func remove_stamina(amount: int) -> void:
	if stamina_empty():
		data.current_stamina = 0
	elif data.current_stamina - amount <= 0:
		data.current_stamina = 0
	else:
		data.current_stamina -= amount

func regen_stamina(amount: int) -> void:
	if stamina_full():
		return
	elif data.current_stamina + amount >= data.max_stamina:
		data.current_stamina = data.max_stamina
	else:
		data.current_stamina += amount

func regen_max_stamina() -> void:
	if stamina_full():
		return
	else:
		regen_stamina(data.stamina_regen_points)
		regen_max_stamina()
