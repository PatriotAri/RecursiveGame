extends CanvasLayer

func _ready() -> void:
	add_to_group(&"death_screen")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Background/VBoxContainer/Respawn.pressed.connect(_on_respawn)
	$Background/VBoxContainer/MainMenu.pressed.connect(_on_main_menu)
	$Background/VBoxContainer/Quit.pressed.connect(_on_quit)

func show_death() -> void:
	Sfx.play(Sfx.death_sting)
	CursorMode.menu()
	visible = true
	get_tree().paused = true

## Back to the most recent save, auto or manual. With no save yet, the run
## starts over.
func _on_respawn() -> void:
	if Saves.load_game(Saves.latest_slot()): return
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit() -> void:
	get_tree().quit()
