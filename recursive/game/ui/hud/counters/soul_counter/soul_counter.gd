extends Control

@export var item: Item

var inventory: Inventory

@onready var label: Label = $Label

func bind(inventory_ref: Inventory) -> void:
	inventory = inventory_ref

func _process(_delta: float) -> void:
	if inventory == null or item == null: return
	label.text = str(inventory.get_count(item.id))
