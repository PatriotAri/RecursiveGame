class_name Inventory

signal changed(item_id: StringName, new_count: int)

var _counts: Dictionary = {}  # StringName -> int

func add(item_id: StringName, amount: int = 1) -> void:
	_counts[item_id] = get_count(item_id) + amount
	changed.emit(item_id, _counts[item_id])

func remove(item_id: StringName, amount: int = 1) -> bool:
	if get_count(item_id) < amount: return false
	_counts[item_id] -= amount
	changed.emit(item_id, _counts[item_id])
	return true

func get_count(item_id: StringName) -> int:
	return _counts.get(item_id, 0)
