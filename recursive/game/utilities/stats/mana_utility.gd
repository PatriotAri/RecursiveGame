class_name ManaUtility

var data: PlayerData

func _init(data_ref: PlayerData) -> void:
	data = data_ref

func mana_empty() -> bool:
	return data.current_mana <= 0

func mana_full() -> bool:
	return data.current_mana >= data.max_mana

#used for mana potions, effects, etc.
func add_mana(amount: int) -> void:
	if mana_full():
		data.current_mana = data.max_mana
	elif data.current_mana + amount >= data.max_mana:
		data.current_mana = data.max_mana
	else:
		data.current_mana += amount

func regen_mana(amount: int) -> void:
	if mana_full():
		return
	elif data.current_mana + amount >= data.max_mana:
		data.current_mana = data.max_mana
	else:
		data.current_mana += amount

func regen_to_max_mana() -> void:
	if mana_full():
		return
	else:
		regen_mana(data.mana_regen_points)
		regen_to_max_mana()

func fill_mana() -> void:
	if mana_full():
		return
	else:
		data.current_mana = data.max_mana

func remove_mana(amount: int) -> void:
	if mana_empty():
		data.current_mana = 0
	elif data.current_mana - amount <= 0:
		data.current_mana = 0
	else:
		data.current_mana -= amount

func degen_mana(amount: int) -> void:
	if mana_empty():
		return
	elif data.current_mana - amount <= 0:
		data.current_mana = 0
	else:
		data.current_mana -= amount

func degen_to_min_mana(amount) -> void:
	if mana_empty():
		return
	else:
		degen_mana(amount)
		degen_to_min_mana(amount)

func empty_mana() -> void:
	if mana_empty():
		return
	else:
		data.current_mana = 0
