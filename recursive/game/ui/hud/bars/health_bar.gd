extends Control

var data: PlayerData

@onready var fill: ColorRect = $Fill

func bind(player_data: PlayerData) -> void:
	data = player_data

func _process(_delta: float) -> void:
	if data == null: return
	var ratio: float = float(data.current_health) / float(data.max_health)
	fill.anchor_top = 1.0 - ratio
