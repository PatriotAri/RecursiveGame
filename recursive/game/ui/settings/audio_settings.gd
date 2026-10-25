class_name AudioSettings

extends PanelContainer

## One slider per bus in AudioManager.BUSES. Rows are built in code so adding
## a bus there is the only step needed for it to show up here.

signal back_pressed

@onready var rows: VBoxContainer = %Rows
@onready var back_button: Button = %BackButton

func _ready() -> void:
	for bus in AudioManager.BUSES:
		_add_row(bus)
	back_button.pressed.connect(back_pressed.emit)
	# Saved on close rather than on every value_changed — a drag fires that
	# dozens of times a second, and each one would be a disk write.
	visibility_changed.connect(_on_visibility_changed)

func _add_row(bus: StringName) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = String(bus)
	label.custom_minimum_size.x = 64
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size.x = 120
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value = AudioManager.get_bus_volume(bus)
	slider.value_changed.connect(func(value: float): AudioManager.set_bus_volume(bus, value))
	row.add_child(label)
	row.add_child(slider)
	rows.add_child(row)

func _on_visibility_changed() -> void:
	if visible:
		# Values can change from elsewhere (another menu's copy of this panel),
		# so re-read rather than trusting what the sliders held last time.
		_sync_sliders()
		back_button.grab_focus()
	else:
		AudioManager.save_settings()

func _sync_sliders() -> void:
	var i := 0
	for row in rows.get_children():
		var slider := row.get_child(1) as HSlider
		if slider and i < AudioManager.BUSES.size():
			slider.set_value_no_signal(AudioManager.get_bus_volume(AudioManager.BUSES[i]))
		i += 1
