extends CanvasLayer

@onready var health_bar: Control = $HealthBar

func _ready() -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if player and "data" in player:
		health_bar.bind(player.data)
