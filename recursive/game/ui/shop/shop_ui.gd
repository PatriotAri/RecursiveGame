extends CanvasLayer

## The buy screen for whichever Shop opened it. Pauses the game while open,
## the same way the inventory does, and only releases a pause it took.

@onready var title: Label = %Title
@onready var gold_label: Label = %Gold
@onready var rows: VBoxContainer = %Rows
@onready var description: Label = %Description
@onready var close_button: Button = %Close

var shop: Shop
var inventory: Inventory
var _paused_by_me:= false

func _ready() -> void:
	add_to_group(&"shop_ui")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(close)

func open(shop_ref: Shop, player: Node) -> void:
	if visible: return
	shop = shop_ref
	inventory = player.data.inventory
	if not inventory.changed.is_connected(_on_inventory_changed):
		inventory.changed.connect(_on_inventory_changed)
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	title.text = shop.shop_name
	_rebuild()

func close() -> void:
	if not visible: return
	visible = false
	if inventory and inventory.changed.is_connected(_on_inventory_changed):
		inventory.changed.disconnect(_on_inventory_changed)
	if _paused_by_me and not _other_pause_holder_visible():
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	_paused_by_me = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	# Interact again walks away from the counter; pause is handled by the
	# pause menu, which closes this first.
	if event.is_action_pressed(&"interact"):
		close()
		get_viewport().set_input_as_handled()

func _other_pause_holder_visible() -> bool:
	for group in [&"death_screen", &"pause_menu", &"inventory_ui"]:
		var node := get_tree().get_first_node_in_group(group)
		if node and node.visible:
			return true
	return false

func _on_inventory_changed(_item: Item, _count: int) -> void:
	_rebuild()

func _rebuild() -> void:
	gold_label.text = "Gold: %d" % inventory.get_count(Shop.GOLD_ID)
	var focused_index := -1
	for child in rows.get_children():
		if child.has_focus(): focused_index = child.get_index()
		rows.remove_child(child)
		child.queue_free()
	for i in shop.entries.size():
		var entry := shop.entries[i]
		if entry == null or entry.item == null: continue
		var button := Button.new()
		var left := shop.stock_left(i)
		var stock_text := "" if left < 0 else ("  (sold out)" if left == 0 else "  (%d left)" % left)
		button.text = "%s — %dg%s" % [entry.item.display_name, entry.price, stock_text]
		button.icon = entry.item.icon
		button.expand_icon = false
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not shop.can_buy(i, inventory)
		button.pressed.connect(_on_buy.bind(i))
		button.mouse_entered.connect(_show_description.bind(entry))
		button.focus_entered.connect(_show_description.bind(entry))
		rows.add_child(button)
	description.text = ""
	# Rebuilding frees the focused button; take focus back so keyboard and
	# pad buying works more than once.
	var target := clampi(focused_index, 0, rows.get_child_count() - 1)
	if rows.get_child_count() > 0:
		var to_focus: Button = rows.get_child(target)
		if to_focus.disabled: to_focus = null
		if to_focus: to_focus.grab_focus()
		else: close_button.grab_focus()
	else:
		close_button.grab_focus()

func _on_buy(index: int) -> void:
	# buy() changes the inventory, which rebuilds the list through the signal.
	shop.buy(index, inventory)

func _show_description(entry: ShopEntry) -> void:
	description.text = entry.item.description
