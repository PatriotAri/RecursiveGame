class_name InventoryRow

extends Button

signal selected(item: Item)

@onready var item_name: Label = $Margin/HBox/ItemName
@onready var count: Label = $Margin/HBox/Count

var item: Item

func _ready() -> void:
	pressed.connect(_on_pressed)

func display(stack: ItemStack) -> void:
	item = stack.item
	item_name.text = stack.item.display_name
	count.text = str(stack.count)

func _on_pressed() -> void:
	selected.emit(item)
