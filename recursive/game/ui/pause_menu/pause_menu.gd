extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var controls_panel: Control = $Background/ControlsPanel
@onready var menu_container: VBoxContainer = $Background/VBoxContainer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	set_process_input(true)
	#starts the pause menu hidden
	visible = false
	#processes the node even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Background/VBoxContainer/Resume.pressed.connect(_on_resume_button_pressed)
	$Background/VBoxContainer/MainMenu.pressed.connect(_on_main_menu_button_pressed)
	$Background/VBoxContainer/Quit.pressed.connect(_on_quit_button_pressed)
	$Background/VBoxContainer/Controls.pressed.connect(_on_controls_button_pressed)
	$Background/ControlsPanel/VBoxContainer/BackButton.pressed.connect(_on_controls_back_pressed)
	controls_panel.visible = false
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume()
		else:
			pause()
			#consumes input so nothing else reacts
		get_viewport().set_input_as_handled()
		
func pause() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	visible = true
	get_tree().paused = true

func resume() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
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
