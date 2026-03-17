extends Control

func _ready() -> void:
	$VBoxContainer/Play.pressed.connect(on_play_pressed)
	$VBoxContainer/Quit.pressed.connect(on_quit_pressed)
	
func on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://game/game.tscn")
	
func on_quit_pressed() -> void:
	get_tree().quit()
