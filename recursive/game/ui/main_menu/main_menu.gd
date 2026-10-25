extends Control

@onready var menu_container: VBoxContainer = $VBoxContainer
@onready var audio_settings: AudioSettings = $AudioSettings
@onready var load_button: Button = $VBoxContainer/Load

func _ready() -> void:
	$VBoxContainer/Play.pressed.connect(on_play_pressed)
	load_button.pressed.connect(on_load_pressed)
	$VBoxContainer/Settings.pressed.connect(on_settings_pressed)
	$VBoxContainer/Quit.pressed.connect(on_quit_pressed)
	audio_settings.back_pressed.connect(on_settings_back_pressed)
	load_button.disabled = not SaveManager.has_save()
	$Version.text = "v" + str(ProjectSettings.get_setting("application/config/version", ""))
	load_button.tooltip_text = SaveManager.describe_save()
	
func on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://game/game.tscn")

func on_load_pressed() -> void:
	SaveManager.load_game()

func on_settings_pressed() -> void:
	menu_container.visible = false
	audio_settings.visible = true

func on_settings_back_pressed() -> void:
	audio_settings.visible = false
	menu_container.visible = true
	
func on_quit_pressed() -> void:
	get_tree().quit()
