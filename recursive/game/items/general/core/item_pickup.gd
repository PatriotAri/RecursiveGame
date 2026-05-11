extends Area2D

@export var item: Item
@export var amount: int = 1

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group(&"player"):
			body.data.inventory.add(item.id, amount)
			print("[Inventory] +%d %s (total: %d)" % [
				amount,
				item.display_name,
				body.data.inventory.get_count(item.id),
			])
			queue_free()
			return
