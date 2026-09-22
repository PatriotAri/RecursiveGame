class_name InventoryRow

extends Button

## Pointed at — mouse hover or keyboard focus. Drives the detail panel.
signal hovered(item: Item)
## Left click, or Enter/Space while focused. Uses or equips.
signal activated(item: Item)

@onready var item_name: Label = $Margin/HBox/ItemName
@onready var count: Label = $Margin/HBox/Count

var item: Item

func _ready() -> void:
	# Button.pressed already fires on left click only — button_mask defaults to
	# the left mouse button — so click-to-use needs no custom input handling.
	# It also fires on Enter/Space while focused, which gives keyboard parity
	# for free.
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_pointed_at)
	focus_entered.connect(_on_pointed_at)

func display(stack: ItemStack) -> void:
	item = stack.item
	item_name.text = stack.item.display_name
	count.text = str(stack.count)

func _on_pointed_at() -> void:
	if item == null: return
	hovered.emit(item)

func _on_pressed() -> void:
	if item == null: return
	activated.emit(item)
