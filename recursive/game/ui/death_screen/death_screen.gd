extends CanvasLayer

func _ready() -> void:
	add_to_group(&"death_screen")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Background/Panel/VBoxContainer/Respawn.pressed.connect(_on_respawn)
	$Background/Panel/VBoxContainer/LoadSave.pressed.connect(_on_load_save)
	$Background/Panel/VBoxContainer/MainMenu.pressed.connect(_on_main_menu)
	$Background/Panel/VBoxContainer/Quit.pressed.connect(_on_quit)

## Can't be closed with the pause key — only by picking one of its options.
func show_death() -> void:
	$Background/Panel/VBoxContainer/LoadSave.disabled = not SaveManager.has_save()
	Menus.open(self, false)

func _on_respawn() -> void:
	Menus.reset()
	get_tree().reload_current_scene()

func _on_load_save() -> void:
	SaveManager.load_game()

func _on_main_menu() -> void:
	Menus.reset()
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit() -> void:
	get_tree().quit()
