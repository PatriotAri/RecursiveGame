extends CanvasLayer

const TAB_ALL := -1

@export var row_scene: PackedScene

@onready var rows: VBoxContainer = %Rows
@onready var list_scroll: ScrollContainer = %ListScroll

@onready var tabs: HBoxContainer = %Tabs

@onready var detail_name: Label = %DetailName
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_desc: RichTextLabel = %DetailDesc

@onready var gold_counter: Control = %GoldCounter
@onready var soul_counter: Control = %SoulCounter

@onready var health_bar: Control = %HealthBar
@onready var stamina_bar: Control = %StaminaBar
@onready var mana_bar: Control = %ManaBar

var inventory: Inventory
var player: Node

var _tab_group := ButtonGroup.new()
var _displayed_id: StringName = &""
var _active_tab: int = TAB_ALL
var _dirty := true
## True only while this menu owns the pause it took in open().
var _paused_by_me := false

func _ready() -> void:
	add_to_group(&"inventory_ui")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_tabs()
	
	player = get_tree().get_first_node_in_group(&"player")
	if player == null:
		# The level instances the player during its own _ready(), so node
		# order decides whether it exists yet. Hud waits the same way.
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group(&"player")
	
	if player and "data" in player:
		bind(player.data.inventory)
	else:
		push_warning("InventoryUi: no player found to bind to.")
	if player and "stats" in player:
		health_bar.bind(player.stats.health)
		stamina_bar.bind(player.stats.stamina)
		mana_bar.bind(player.stats.mana)
		
func bind(inventory_ref: Inventory) -> void:
	if inventory != null and inventory.changed.is_connected(_on_inventory_changed):
		inventory.changed.disconnect(_on_inventory_changed)
	inventory = inventory_ref
	if inventory != null:
		inventory.changed.connect(_on_inventory_changed)
	gold_counter.bind(inventory)
	soul_counter.bind(inventory)
	_dirty = true

# --- tabs ---------------------------------------------------------------

## Text, enabled state, toggle mode and focus mode all come from the scene.
## This only wires up behaviour.
func _setup_tabs() -> void:
	var filters := {
		"TabAll": TAB_ALL,
		"TabArmor": Item.Category.ARMOR,
		"TabWeapons": Item.Category.WEAPON,
		"TabConsumeables": Item.Category.CONSUMEABLE,
	}
	for child in tabs.get_children():
		var tab := child as Button
		if tab == null: continue
		var key := String(tab.name)
		if not filters.has(key): continue
		var category := int(filters[key])
		tab.button_group = _tab_group
		tab.button_pressed = category == _active_tab
		tab.pressed.connect(_on_tab_pressed.bind(category))

func _on_tab_pressed(category: int) -> void:
	if _active_tab == category: return
	_active_tab = category
	_rebuild()

# --- open / close -------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"inventory"): return
	if visible:
		close()
	elif _can_open():
		open()
	get_viewport().set_input_as_handled()

func _can_open() -> bool:
	return not get_tree().paused and not _other_pause_holder_visible()

func open() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	if _dirty: _rebuild()
	_focus_selected_or_first()

func close() -> void:
	visible = false
	# Only release the pause we took ourselves, and only if nothing else still
	# needs the game frozen. Unconditionally unpausing resumed the game
	# underneath the death screen if the inventory was open when you died.
	if _paused_by_me and not _other_pause_holder_visible():
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	_paused_by_me = false

func _other_pause_holder_visible() -> bool:
	for group in [&"death_screen", &"pause_menu"]:
		var node := get_tree().get_first_node_in_group(group)
		if node and node.visible:
			return true
	return false

# --- list ---------------------------------------------------------------

## Currency is tracked by the counters and never appears as a row, whatever
## tab is active.
func _is_listable(item: Item) -> bool:
	return item != null and item.category != Item.Category.CURRENCY

func _passes_filter(item: Item) -> bool:
	if not _is_listable(item): return false
	return _active_tab == TAB_ALL or item.category == _active_tab

func _on_inventory_changed(item: Item, _new_count: int) -> void:
	# Picking up gold used to tear down and rebuild every row for an item
	# that can never appear in the list.
	if not _is_listable(item): return
	if visible:
		_rebuild()
	else:
		_dirty = true

func _rebuild() -> void:
	_dirty = false
	if inventory == null or row_scene == null: return
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var still_displayed := false
	var stacks := inventory.get_stacks()
	# Dictionary order is insertion order, so rows reshuffle as you pick things
	# up mid-run. Alphabetical keeps an item in the same place.
	stacks.sort_custom(func(a, b): return a.item.display_name < b.item.display_name)
	for stack in inventory.get_stacks():
		if not _passes_filter(stack.item): continue
		var row: InventoryRow = row_scene.instantiate()
		rows.add_child(row)
		row.display(stack)
		if stack.item.id == _displayed_id:
			still_displayed = true
		row.hovered.connect(_on_row_hovered)
		row.activated.connect(_on_row_activated)
		# Keep the focused row on screen when navigating by keyboard or pad.
		row.focus_entered.connect(list_scroll.ensure_control_visible.bind(row))
	if not still_displayed:
		_displayed_id = &""
	_show_detail()
	# _rebuild() frees and recreates every row, so whatever had focus is gone.
	# Selection survives via _displayed_id; focus has to be re-taken by hand.
	if visible:
		_focus_selected_or_first()

func _focus_selected_or_first() -> void:
	var first: InventoryRow = null
	for child in rows.get_children():
		var row := child as InventoryRow
		if row == null: continue
		if first == null: first = row
		if row.item != null and row.item.id == _displayed_id:
			row.grab_focus()
			return
	if first != null:
		first.grab_focus()

## The detail panel is sticky — it keeps showing the last item you pointed at
## rather than blanking when the mouse leaves the list.
func _on_row_hovered(item: Item) -> void:
	if item.id == _displayed_id: return
	_displayed_id = item.id
	_show_detail()

func _on_row_activated(item: Item) -> void:
	if player == null: return
	match item.category:
		Item.Category.CONSUMEABLE:
			# The `is` check rather than a cast: a .tres whose category was set
			# to CONSUMEABLE but built from plain Item would otherwise pass a
			# null into try_use().
			if item is ConsumableItem and player.player_consumable_system:
				# try_use() removes one, which fires changed -> _rebuild(), so
				# the row's count refreshes itself.
				player.player_consumable_system.try_use(player.data, item)
		Item.Category.WEAPON, Item.Category.ARMOR:
			pass # equipment lands in its own phase
		_:
			pass

func _show_detail() -> void:
	var stack: ItemStack = inventory.get_stack(_displayed_id) if inventory else null
	var has := stack != null
	detail_name.visible = has
	detail_icon.visible = has
	detail_desc.visible = has
	if not has: return
	detail_name.text = stack.item.display_name
	detail_icon.texture = stack.item.icon
	detail_desc.text = stack.item.description
