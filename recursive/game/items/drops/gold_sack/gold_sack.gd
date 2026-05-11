extends Area2D

var amount: int = 0  # set by spawner before adding to tree

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group(&"player"):
			body.data.gold += amount
			queue_free()
			return
