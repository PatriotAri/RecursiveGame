class_name SaveSlotsMenu

extends Control

## The save slot list, opened for saving or for loading. Shows the auto-save
## and each manual slot with where and when it was saved. Saving over a
## filled slot takes a second press to confirm. Shared by the pause menu, the
## shop and the main menu, like SettingsMenu.

## Emitted on Back. Whichever menu opened this one shows itself again.
signal closed

enum Mode {SAVE, LOAD}

@onready var title: Label = %Title
@onready var rows: VBoxContainer = %Rows
@onready var status: Label = %Status
@onready var back_button: Button = %BackButton

var mode := Mode.LOAD
## One button per slot, indexed by slot number: the auto-save is 0.
var _buttons: Array[Button] = []
## A filled slot pressed once in save mode, waiting on the second press that
## confirms overwriting it. -1 when there isn't one.
var _armed_slot := -1

func _ready() -> void:
	visible = false
	back_button.pressed.connect(close)
	for slot in Saves.MANUAL_SLOTS + 1:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_slot_pressed.bind(slot))
		rows.add_child(button)
		_buttons.append(button)

func open(new_mode: Mode) -> void:
	mode = new_mode
	title.text = "SAVE GAME" if mode == Mode.SAVE else "LOAD GAME"
	status.text = ""
	_armed_slot = -1
	_refresh()
	visible = true
	_focus_first()

func close() -> void:
	visible = false
	closed.emit()

func _on_slot_pressed(slot: int) -> void:
	if mode == Mode.LOAD:
		# Read again on press: the file may have changed since the list was
		# drawn.
		if not Saves.load_game(slot):
			status.text = "That save couldn't be loaded."
			_refresh()
		return
	var filled := not Saves.slot_info(slot).is_empty()
	if filled and _armed_slot != slot:
		_armed_slot = slot
		status.text = ""
		_refresh()
		return
	_armed_slot = -1
	if Saves.save_game(slot):
		status.text = "Saved to slot %d." % slot
	else:
		status.text = "Couldn't save."
	_refresh()

func _refresh() -> void:
	for slot in _buttons.size():
		var info := Saves.slot_info(slot)
		var button := _buttons[slot]
		button.text = _row_text(slot, info)
		if mode == Mode.SAVE:
			# The auto-save is shown for reference but only the game writes it.
			button.disabled = slot == Saves.AUTO_SLOT
		else:
			button.disabled = info.is_empty()

func _row_text(slot: int, info: Dictionary) -> String:
	var slot_name := "Auto-save" if slot == Saves.AUTO_SLOT else "Slot %d" % slot
	if slot == _armed_slot:
		return "%s:  Overwrite? Press again to confirm." % slot_name
	if info.is_empty():
		return "%s:  Empty" % slot_name
	return "%s:  %s   %s" % [slot_name, info["label"], _format_time(info["saved_at"])]

func _focus_first() -> void:
	for button in _buttons:
		if not button.disabled:
			button.grab_focus()
			return
	back_button.grab_focus()

## Saves hold UTC; this shows the player's local time.
static func _format_time(unix_time: float) -> String:
	var bias_minutes: int = Time.get_time_zone_from_system()["bias"]
	var t := Time.get_datetime_dict_from_unix_time(int(unix_time) + bias_minutes * 60)
	return "%d-%02d-%02d %02d:%02d" % [t["year"], t["month"], t["day"], t["hour"], t["minute"]]
