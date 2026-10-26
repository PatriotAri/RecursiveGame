class_name ShopUi

extends CanvasLayer

## The vendor's buy/sell menu. Buys at an item's value and sells back at half,
## rounded down. Equipped gear can't be sold — unequip it first — so the
## weapon in your hand can't go by accident. The vendor is also one of the
## places the game can be saved.

const SELL_RATE := 0.5

@onready var buy_rows: VBoxContainer = %BuyRows
@onready var sell_rows: VBoxContainer = %SellRows
@onready var gold_counter: Control = %GoldCounter
@onready var back_button: Button = %BackButton
@onready var save_button: Button = %SaveButton
@onready var root: Control = $Root
@onready var save_slots_menu: SaveSlotsMenu = $SaveSlotsMenu

var _vendor: Vendor
var _player: Node
## True only while this menu owns the pause it took in open().
var _paused_by_me := false

func _ready() -> void:
	add_to_group(&"shop_ui")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_button.pressed.connect(close)
	save_button.pressed.connect(_on_save_pressed)
	save_slots_menu.closed.connect(_on_save_slots_closed)

static func sell_price(item: Item) -> int:
	return floori(item.value * SELL_RATE)

func open(vendor: Vendor, player: Node) -> void:
	_vendor = vendor
	_player = player
	var inventory: Inventory = player.data.inventory
	gold_counter.bind(inventory)
	if not inventory.changed.is_connected(_on_inventory_changed):
		inventory.changed.connect(_on_inventory_changed)
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	Sfx.play(Sfx.menu_open)
	save_button.disabled = not Saves.can_save()
	_rebuild()
	_focus_first()

func close() -> void:
	if not visible: return
	if save_slots_menu.visible:
		save_slots_menu.close()
	visible = false
	var inventory: Inventory = _player.data.inventory
	if inventory.changed.is_connected(_on_inventory_changed):
		inventory.changed.disconnect(_on_inventory_changed)
	if _paused_by_me:
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	_paused_by_me = false
	Sfx.play(Sfx.menu_close)

func _unhandled_input(event: InputEvent) -> void:
	# The interact key closes the shop too, so opening and closing it is the
	# same key. Esc is handled by the pause menu, which closes this first.
	if visible and event.is_action_pressed(&"interact"):
		close()
		get_viewport().set_input_as_handled()

func _on_save_pressed() -> void:
	root.visible = false
	save_slots_menu.open(SaveSlotsMenu.Mode.SAVE)

func _on_save_slots_closed() -> void:
	root.visible = true
	save_button.grab_focus()

func _buy(item: Item) -> void:
	var inventory: Inventory = _player.data.inventory
	if item.value > 0 and not inventory.remove(_vendor.gold_item.id, item.value):
		Sfx.play(Sfx.refused)
		return
	inventory.add(item, 1)
	Sfx.play(_vendor.purchase_sound)

func _sell(item: Item) -> void:
	if _player.data.equipment.is_equipped(item):
		Sfx.play(Sfx.refused)
		return
	var inventory: Inventory = _player.data.inventory
	if not inventory.remove(item.id, 1): return
	var price:= sell_price(item)
	if price > 0:
		inventory.add(_vendor.gold_item, price)
	Sfx.play(_vendor.sale_sound)

func _on_inventory_changed(_item: Item, _new_count: int) -> void:
	if visible:
		_rebuild()

func _rebuild() -> void:
	# Keeps keyboard focus on the same row across a rebuild, by its text.
	var focused:= get_viewport().gui_get_focus_owner()
	var focused_text: String = focused.text if focused is Button else ""
	for rows in [buy_rows, sell_rows]:
		for child in rows.get_children():
			rows.remove_child(child)
			child.queue_free()
	for item in _vendor.stock:
		if item == null: continue
		_add_row(buy_rows, "%s   %dg" % [item.display_name, item.value], _buy.bind(item))
	var stacks: Array[ItemStack] = _player.data.inventory.get_stacks()
	stacks.sort_custom(func(a, b): return a.item.display_name < b.item.display_name)
	var equipment: Equipment = _player.data.equipment
	for stack in stacks:
		if stack.item.category == Item.Category.CURRENCY: continue
		var text:= "%s x%d   %dg" % [stack.item.display_name, stack.count, sell_price(stack.item)]
		if equipment.is_equipped(stack.item):
			text += "   (equipped)"
		_add_row(sell_rows, text, _sell.bind(stack.item))
	if sell_rows.get_child_count() == 0:
		var empty:= Label.new()
		empty.text = "Nothing to sell"
		sell_rows.add_child(empty)
	for rows in [buy_rows, sell_rows]:
		for row in rows.get_children():
			if row is Button and row.text == focused_text:
				row.grab_focus()
				return
	_focus_first()

func _add_row(rows: VBoxContainer, text: String, on_pressed: Callable) -> void:
	var row:= Button.new()
	row.text = text
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.pressed.connect(on_pressed)
	rows.add_child(row)

func _focus_first() -> void:
	for rows in [buy_rows, sell_rows]:
		for row in rows.get_children():
			if row is Button:
				row.grab_focus()
				return
