extends Control

@onready var menu_container: VBoxContainer = $VBoxContainer
@onready var settings_menu: SettingsMenu = $SettingsMenu

func _ready() -> void:
	$VBoxContainer/Play.pressed.connect(on_play_pressed)
	$VBoxContainer/Settings.pressed.connect(on_settings_pressed)
	$VBoxContainer/Quit.pressed.connect(on_quit_pressed)
	settings_menu.closed.connect(on_settings_closed)
	
func on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://game/game.tscn")
	
func on_settings_pressed() -> void:
	menu_container.visible = false
	settings_menu.open()

func on_settings_closed() -> void:
	menu_container.visible = true

func on_quit_pressed() -> void:
	get_tree().quit()
