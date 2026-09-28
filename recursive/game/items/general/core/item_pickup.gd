extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

@export var item: Item
@export var amount: int = 1

func _ready() -> void:
	if item == null:
		push_error("%s: no item assigned; pickup disabled." % name)
		set_deferred("monitoring", false)
		return
	# The pickup's look comes from the item, so a new item needs no new scene.
	sprite.texture = item.icon
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group(&"player"):
		return
	body.data.inventory.add(item, amount)
	set_deferred("monitoring", false)
	queue_free()
