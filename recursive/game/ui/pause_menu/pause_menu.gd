extends Control

@onready var background: ColorRect = $Background

func _ready() -> void:
	set_process_input(true)
	#starts the pause menu hidden
	visible = false
	#processes the node even when paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$Background/VBoxContainer/Resume.pressed.connect(_on_resume_button_pressed)
	$Background/VBoxContainer/MainMenu.pressed.connect(_on_main_menu_button_pressed)
	$Background/VBoxContainer/Quit.pressed.connect(_on_quit_button_pressed)

func _input(event: InputEvent) -> void:
	print("input receieve: ", event)
	if event.is_action_pressed("pause"):
		print("Pause pressed.")
		if get_tree().paused:
			resume()
		else:
			pause()
			#consumes input so nothing else reacts
		get_viewport().set_input_as_handled()
		
func pause() -> void:
	visible = true
	get_tree().paused = true

func resume() -> void:
	visible = false
	get_tree().paused = false
	
func _on_resume_button_pressed() -> void:
	resume()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()
