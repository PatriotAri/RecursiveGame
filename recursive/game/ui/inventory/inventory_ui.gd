extends CanvasLayer

const TAB_ALL := -1

@export var row_scene: PackedScene

@onready var rows: VBoxContainer = %Rows
@onready var detail_name: Label = %DetailName
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_desc: RichTextLabel = %DetailDesc
@onready var gold_counter: Control = %GoldCounter
@onready var soul_counter: Control = %SoulCounter

var inventory: Inventory

var _row_group := ButtonGroup.new()
var _selected_id: StringName = &""
var _active_tab: int = TAB_ALL
var _dirty := true

func _ready() -> void:
	add_to_group(&"inventory_ui")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var player := get_tree().get_first_node_in_group(&"player")
	if player and "data" in player:
		bind(player.data.inventory)

func bind(inventory_ref: Inventory) -> void:
	if inventory != null and inventory.changed.is_connected(_on_inventory_changed):
		inventory.changed.disconnect(_on_inventory_changed)
	inventory = inventory_ref
	if inventory != null:
		inventory.changed.connect(_on_inventory_changed)
	gold_counter.bind(inventory)
	soul_counter.bind(inventory)
	_dirty = true

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"inventory"): return
	if visible:
		close()
	elif _can_open():
		open()
	get_viewport().set_input_as_handled()

func _can_open() -> bool:
	var death_screen := get_tree().get_first_node_in_group(&"death_screen")
	if death_screen and death_screen.visible: return false
	return not get_tree().paused

func open() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	if _dirty: _rebuild()

func close() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	get_tree().paused = false

func _on_inventory_changed(_item: Item, _new_count: int) -> void:
	if visible:
		_rebuild()
	else:
		_dirty = true

func _passes_filter(item: Item) -> bool:
	if item.category == Item.Category.CURRENCY:
		return false
	if _active_tab == TAB_ALL:
		return true
	return item.category == _active_tab

func _rebuild() -> void:
	_dirty = false
	if inventory == null or row_scene == null: return
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var still_selected := false
	for stack in inventory.get_stacks():
		if not _passes_filter(stack.item): continue
		var row: InventoryRow = row_scene.instantiate()
		row.button_group = _row_group
		rows.add_child(row)
		row.display(stack)
		if stack.item.id == _selected_id:
			row.button_pressed = true
			still_selected = true
		row.selected.connect(_on_row_selected)
	if not still_selected:
		_selected_id = &""
	_show_detail()

func _on_row_selected(item: Item) -> void:
	_selected_id = item.id
	_show_detail()

func _show_detail() -> void:
	var stack: ItemStack = inventory.get_stack(_selected_id) if inventory else null
	var has := stack != null
	detail_name.visible = has
	detail_icon.visible = has
	detail_desc.visible = has
	if not has: return
	detail_name.text = stack.item.display_name
	detail_icon.texture = stack.item.icon
	detail_desc.text = stack.item.description
