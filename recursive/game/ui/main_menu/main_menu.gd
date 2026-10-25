extends Control

@onready var menu_container: VBoxContainer = $VBoxContainer
@onready var audio_settings: AudioSettings = $AudioSettings

func _ready() -> void:
	$VBoxContainer/Play.pressed.connect(on_play_pressed)
	$VBoxContainer/Settings.pressed.connect(on_settings_pressed)
	$VBoxContainer/Quit.pressed.connect(on_quit_pressed)
	audio_settings.back_pressed.connect(on_settings_back_pressed)
	
func on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://game/game.tscn")

func on_settings_pressed() -> void:
	menu_container.visible = false
	audio_settings.visible = true

func on_settings_back_pressed() -> void:
	audio_settings.visible = false
	menu_container.visible = true
	
func on_quit_pressed() -> void:
	get_tree().quit()
