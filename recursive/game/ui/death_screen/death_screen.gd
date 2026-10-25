extends CanvasLayer

func _ready() -> void:
	add_to_group(&"death_screen")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Background/Panel/VBoxContainer/Respawn.pressed.connect(_on_respawn)
	$Background/Panel/VBoxContainer/LoadSave.pressed.connect(_on_load_save)
	$Background/Panel/VBoxContainer/MainMenu.pressed.connect(_on_main_menu)
	$Background/Panel/VBoxContainer/Quit.pressed.connect(_on_quit)

func show_death() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$Background/Panel/VBoxContainer/LoadSave.disabled = not SaveManager.has_save()
	visible = true
	get_tree().paused = true

func _on_respawn() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_load_save() -> void:
	SaveManager.load_game()

func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit() -> void:
	get_tree().quit()
