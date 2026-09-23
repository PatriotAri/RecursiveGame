extends Control

@export var item: Item

var inventory: Inventory

@onready var label: Label = $Margin/HBox/Label

func bind(inventory_ref: Inventory) -> void:
	if inventory != null and inventory.changed.is_connected(_on_inventory_changed):
		inventory.changed.disconnect(_on_inventory_changed)
	inventory = inventory_ref
	if inventory != null:
		inventory.changed.connect(_on_inventory_changed)
	_refresh()

func _on_inventory_changed(_item: Item, _new_count: int) -> void:
	_refresh()

func _refresh() -> void:
	if inventory == null or item == null: return
	label.text = str(inventory.get_count(item.id))
