class_name ItemStack
var item: Item

var count: int

func _init(p_item: Item, p_count: int = 0) -> void:
	item = p_item
	count = p_count
