extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var controls_panel: Control = $Background/ControlsPanel
@onready var menu_container: Control = $Background/Panel
@onready var audio_settings: AudioSettings = $Background/AudioSettings
@onready var load_button: Button = $Background/Panel/VBoxContainer/Load
@onready var status_label: Label = $Background/Panel/VBoxContainer/Status

func _ready() -> void:
	add_to_group(&"pause_menu")
	Menus.pause_menu = self
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	#starts the pause menu hidden
	visible = false
	#processes the node even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Background/Panel/VBoxContainer/Resume.pressed.connect(_on_resume_button_pressed)
	$Background/Panel/VBoxContainer/MainMenu.pressed.connect(_on_main_menu_button_pressed)
	$Background/Panel/VBoxContainer/Quit.pressed.connect(_on_quit_button_pressed)
	$Background/Panel/VBoxContainer/Controls.pressed.connect(_on_controls_button_pressed)
	$Background/Panel/VBoxContainer/Audio.pressed.connect(_on_audio_button_pressed)
	$Background/Panel/VBoxContainer/Save.pressed.connect(_on_save_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	audio_settings.back_pressed.connect(_on_audio_back_pressed)
	$Background/ControlsPanel/VBoxContainer/BackButton.pressed.connect(_on_controls_back_pressed)
	controls_panel.visible = false
	
## Opened by Menus when the pause key is pressed with nothing else open.
func open() -> void:
	status_label.text = ""
	load_button.disabled = not SaveManager.has_save()
	Menus.open(self)

func close() -> void:
	controls_panel.visible = false
	audio_settings.visible = false
	menu_container.visible = true
	Menus.close(self)

func _on_resume_button_pressed() -> void:
	close()

func _on_main_menu_button_pressed() -> void:
	Menus.reset()
	get_tree().change_scene_to_file("res://main.tscn")
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_controls_button_pressed() -> void:
	menu_container.visible = false
	controls_panel.visible = true

func _on_controls_back_pressed() -> void:
	controls_panel.visible = false
	menu_container.visible = true

func _on_audio_button_pressed() -> void:
	menu_container.visible = false
	audio_settings.visible = true

func _on_audio_back_pressed() -> void:
	audio_settings.visible = false
	menu_container.visible = true

func _on_save_button_pressed() -> void:
	if SaveManager.save_game():
		status_label.text = "Game saved"
		load_button.disabled = false
	else:
		status_label.text = "Couldn't save"

func _on_load_button_pressed() -> void:
	if not SaveManager.load_game():
		status_label.text = "No save to load"
