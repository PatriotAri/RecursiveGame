class_name SettingsMenu

extends Control

## Volume sliders for every bus in Settings.AUDIO_BUSES. Changes apply while
## a slider moves and are saved when it's let go and when the menu closes.
## Shared by the main menu and the pause menu.

## Emitted on Back. Whichever menu opened this one shows itself again.
signal closed

@onready var rows: VBoxContainer = %Rows
@onready var back_button: Button = %BackButton

var _sliders: Dictionary = {}  # StringName bus -> HSlider
var _value_labels: Dictionary = {}  # StringName bus -> Label

func _ready() -> void:
	visible = false
	back_button.pressed.connect(close)
	for bus in Settings.AUDIO_BUSES:
		_add_volume_row(bus)

func open() -> void:
	# The main menu and the pause menu each have their own copy of this menu,
	# so the stored values may have changed since this one last showed.
	for bus in _sliders:
		var percent := roundf(Settings.get_volume(bus) * 100.0)
		_sliders[bus].set_value_no_signal(percent)
		_value_labels[bus].text = "%d%%" % percent
	visible = true
	_sliders[Settings.AUDIO_BUSES[0]].grab_focus()

func close() -> void:
	# Keyboard and gamepad changes never fire drag_ended, so this save is
	# what catches them.
	Settings.save()
	visible = false
	closed.emit()

func _add_volume_row(bus: StringName) -> void:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = String(bus)
	name_label.custom_minimum_size.x = 70
	var slider := HSlider.new()
	slider.max_value = 100
	slider.step = 1
	slider.custom_minimum_size.x = 150
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 45
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(name_label)
	row.add_child(slider)
	row.add_child(value_label)
	rows.add_child(row)
	_sliders[bus] = slider
	_value_labels[bus] = value_label
	# Connected after the row is filled in, so building the menu doesn't
	# write every volume straight back to Settings.
	slider.value_changed.connect(_on_volume_changed.bind(bus))
	slider.drag_ended.connect(func(_value_changed: bool) -> void: Settings.save())

func _on_volume_changed(percent: float, bus: StringName) -> void:
	Settings.set_volume(bus, percent / 100.0)
	_value_labels[bus].text = "%d%%" % percent
