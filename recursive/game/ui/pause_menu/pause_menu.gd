extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var controls_panel: Control = $Background/ControlsPanel
@onready var menu_container: VBoxContainer = $Background/VBoxContainer
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var save_slots_menu: SaveSlotsMenu = $SaveSlotsMenu
@onready var save_button: Button = $Background/VBoxContainer/Save
@onready var load_button: Button = $Background/VBoxContainer/Load

func _ready() -> void:
	add_to_group(&"pause_menu")
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	set_process_input(true)
	#starts the pause menu hidden
	visible = false
	#processes the node even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Background/VBoxContainer/Resume.pressed.connect(_on_resume_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	$Background/VBoxContainer/MainMenu.pressed.connect(_on_main_menu_button_pressed)
	$Background/VBoxContainer/Quit.pressed.connect(_on_quit_button_pressed)
	$Background/VBoxContainer/Controls.pressed.connect(_on_controls_button_pressed)
	$Background/VBoxContainer/Settings.pressed.connect(_on_settings_button_pressed)
	settings_menu.closed.connect(_on_settings_closed)
	save_slots_menu.closed.connect(_on_save_slots_closed)
	$Background/ControlsPanel/VBoxContainer/BackButton.pressed.connect(_on_controls_back_pressed)
	controls_panel.visible = false
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var death_screen := get_tree().get_first_node_in_group(&"death_screen")
		if death_screen and death_screen.visible:
			get_viewport().set_input_as_handled()
			return
		var inventory_ui :=  get_tree().get_first_node_in_group(&"inventory_ui")
		if inventory_ui and inventory_ui.visible:
			inventory_ui.close()
			get_viewport().set_input_as_handled()
			return
		var shop_ui := get_tree().get_first_node_in_group(&"shop_ui")
		if shop_ui and shop_ui.visible:
			shop_ui.close()
			get_viewport().set_input_as_handled()
			return
		if get_tree().paused:
			resume()
		else:
			pause()
			#consumes input so nothing else reacts
		get_viewport().set_input_as_handled()
		
func pause() -> void:
	Sfx.play(Sfx.menu_open)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_save_buttons()
	visible = true
	get_tree().paused = true

func resume() -> void:
	Sfx.play(Sfx.menu_close)
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	# Closing through the menu saves, so unpausing straight out of it does
	# too.
	if settings_menu.visible:
		settings_menu.close()
	if save_slots_menu.visible:
		save_slots_menu.close()
	controls_panel.visible = false
	menu_container.visible = true
	visible = false
	get_tree().paused = false
	
func _on_resume_button_pressed() -> void:
	resume()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_controls_button_pressed() -> void:
	menu_container.visible = false
	controls_panel.visible = true

func _on_controls_back_pressed() -> void:
	controls_panel.visible = false
	menu_container.visible = true

func _on_settings_button_pressed() -> void:
	background.visible = false
	settings_menu.open()

func _on_settings_closed() -> void:
	background.visible = true

func _on_save_button_pressed() -> void:
	background.visible = false
	save_slots_menu.open(SaveSlotsMenu.Mode.SAVE)

func _on_load_button_pressed() -> void:
	background.visible = false
	save_slots_menu.open(SaveSlotsMenu.Mode.LOAD)

func _on_save_slots_closed() -> void:
	background.visible = true
	# A save just made is now there to load.
	_refresh_save_buttons()

## Saving is only allowed between rounds and on the airship; the tooltip says
## why the button is greyed out the rest of the time.
func _refresh_save_buttons() -> void:
	save_button.disabled = not Saves.can_save()
	save_button.tooltip_text = "You can save between rounds or on the airship." if save_button.disabled else ""
	load_button.disabled = not Saves.has_any_save()
