extends Control

var data: PlayerData

@onready var label: Label = $Label

func bind(data_ref: PlayerData) -> void:
	data = data_ref

func _process(_delta: float) -> void:
	if data == null: return
	label.text = str(data.gold)
