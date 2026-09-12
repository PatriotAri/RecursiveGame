class_name Inventory

signal changed(item: Item, new_count: int)

var _stacks: Dictionary = {}  # StringName -> ItemStack

func add(item: Item, amount: int = 1) -> void:
	if item == null or amount <= 0: return
	var stack: ItemStack = _stacks.get(item.id)
	if stack == null:
		stack = ItemStack.new(item, 0)
		_stacks[item.id] = stack
	stack.count += amount
	changed.emit(item, stack.count)

func remove(item_id: StringName, amount: int = 1) -> bool:
	var stack: ItemStack = _stacks.get(item_id)
	if stack == null or amount <= 0 or stack.count < amount: return false
	stack.count -= amount
	if stack.count == 0:
		_stacks.erase(item_id)
	changed.emit(stack.item, stack.count)
	return true

func get_count(item_id: StringName) -> int:
	var stack: ItemStack = _stacks.get(item_id)
	return stack.count if stack else 0

func get_stack(item_id: StringName) -> ItemStack:
	return _stacks.get(item_id)

func get_stacks() -> Array[ItemStack]:
	var result: Array[ItemStack] = []
	for id in _stacks:
		result.append(_stacks[id])
	return result
