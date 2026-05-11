extends CanvasLayer

@onready var health_bar: Control = $HealthBar
@onready var gold_counter: Control = $GoldCounter
@onready var soul_counter: Control = $SoulCounter

func _ready() -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if player and "data" in player:
		health_bar.bind(player.data)
		gold_counter.bind(player.data)
		soul_counter.bind(player.data)
