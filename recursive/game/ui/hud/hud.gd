extends CanvasLayer

@onready var health_bar: Control = $HealthBar

func _ready() -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	print("HUD ready — player found: ", player)
	if player and "data" in player:
		print("HUD ready — player.data: ", player.data)
		health_bar.bind(player.data)
	else:
		print("HUD ready — bind skipped")
