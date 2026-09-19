extends Area2D

@export var item: Item
@export var amount: int = 1

func _ready() -> void:
	if item == null:
		push_error("%s: no item assigned; pickup disabled." % name)
		set_deferred("monitoring", false)
		return
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(&"player"):
		return
	body.data.inventory.add(item, amount)
	set_deferred("monitoring", false)
	queue_free()
