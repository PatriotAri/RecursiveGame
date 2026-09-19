class_name InventoryRow

extends Button

signal selected(item: Item)

@onready var item_name: Label = $Margin/HBox/ItemName
@onready var count: Label = $Margin/HBox/Count

var item: Item

func _ready() -> void:
	pressed.connect(_on_activated)
	# Selection follows keyboard/gamepad focus, not just clicks.
	focus_entered.connect(_on_activated)

func display(stack: ItemStack) -> void:
	item = stack.item
	item_name.text = stack.item.display_name
	count.text = str(stack.count)

func _on_activated() -> void:
	if item == null: return
	button_pressed = true
	selected.emit(item)
