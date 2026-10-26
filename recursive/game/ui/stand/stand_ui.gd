class_name StandUi

extends CanvasLayer

## The menu every airship stand opens: its entries on the left, the selected
## one's detail and actions on the right. What's listed and what the buttons
## do come from the stand (see Stand); this only draws it and rebuilds after
## every press, so prices and greyed-out reasons are always current.

@onready var title: Label = %Title
@onready var list_rows: VBoxContainer = %ListRows
@onready var detail_icon: TextureRect = %DetailIcon
@onready var detail_title: Label = %DetailTitle
@onready var detail_text: Label = %DetailText
@onready var action_rows: VBoxContainer = %ActionRows
@onready var gold_counter: Control = %GoldCounter
@onready var soul_counter: Control = %SoulCounter
@onready var back_button: Button = %BackButton

var _stand: Stand
var _player: Node
var _selected: Variant
## True only while this menu owns the pause it took in open().
var _paused_by_me := false

func _ready() -> void:
	add_to_group(&"stand_ui")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_button.pressed.connect(close)

func open(stand: Stand, player: Node) -> void:
	_stand = stand
	_player = player
	gold_counter.bind(player.data.inventory)
	soul_counter.bind(player.data.inventory)
	title.text = stand.title.to_upper()
	visible = true
	CursorMode.menu()
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	Sfx.play(Sfx.menu_open)
	_selected = stand.first_selection(player)
	_rebuild()
	_focus_first()

func close() -> void:
	if not visible: return
	visible = false
	if _paused_by_me:
		get_tree().paused = false
		CursorMode.gameplay()
	_paused_by_me = false
	Sfx.play(Sfx.menu_close)

func _unhandled_input(event: InputEvent) -> void:
	# The interact key closes it too, like the shop. Esc is handled by the
	# pause menu, which closes this first.
	if visible and event.is_action_pressed(&"interact"):
		close()
		get_viewport().set_input_as_handled()

func _press(row: StandRow) -> void:
	var next: Variant = row.on_pressed.call()
	if next != null:
		_selected = next
	_rebuild()

func _rebuild() -> void:
	# Keeps keyboard focus on the same row across a rebuild, by its text.
	var focused := get_viewport().gui_get_focus_owner()
	var focused_text: String = focused.text if focused is Button else ""
	for rows in [list_rows, action_rows]:
		for child in rows.get_children():
			rows.remove_child(child)
			child.queue_free()
	var entries := _stand.list_rows(_player, _selected)
	if entries.is_empty():
		_add_label(list_rows, _stand.empty_text())
	for row in entries:
		_add_row(list_rows, row)
	var info := _stand.detail(_player, _selected)
	if info == null and not entries.is_empty():
		# What was selected is gone (sold, say): fall back to the first entry.
		_selected = _stand.first_selection(_player)
		info = _stand.detail(_player, _selected)
	detail_icon.visible = info != null and info.icon != null
	detail_title.visible = info != null
	detail_text.visible = info != null
	if info:
		detail_icon.texture = info.icon
		detail_icon.material = info.icon_material
		detail_title.text = info.title
		detail_text.text = info.text
		for row in info.rows:
			_add_row(action_rows, row)
	for button in _buttons(list_rows) + _buttons(action_rows):
		if button.text == focused_text and not button.disabled:
			button.grab_focus()
			return
	_focus_first()

func _add_row(rows: VBoxContainer, row: StandRow) -> void:
	if not row.on_pressed.is_valid():
		_add_label(rows, row.text)
	else:
		var button := Button.new()
		button.text = ("> " if row.selected else "") + row.text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = row.disabled
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_press.bind(row))
		if row.icon:
			# Beside the button rather than on it, so the icon alone can be drawn
			# recoloured to its material.
			var line := HBoxContainer.new()
			var icon := TextureRect.new()
			icon.texture = row.icon
			icon.material = row.icon_material
			icon.custom_minimum_size = Vector2(16, 16)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			line.add_child(icon)
			line.add_child(button)
			rows.add_child(line)
		else:
			rows.add_child(button)
	if row.note != "":
		var note := _add_label(rows, "    " + row.note)
		note.modulate = Color(1, 1, 1, 0.6)

func _add_label(rows: VBoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(label)
	return label

func _focus_first() -> void:
	for button in _buttons(action_rows) + _buttons(list_rows):
		if not button.disabled:
			button.grab_focus()
			return

## Every button in `rows`, including those beside an icon.
func _buttons(rows: VBoxContainer) -> Array[Button]:
	var result: Array[Button] = []
	for button in rows.find_children("*", "Button", true, false):
		result.append(button)
	return result
