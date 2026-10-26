extends Control

@onready var menu_container: VBoxContainer = $VBoxContainer
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var save_slots_menu: SaveSlotsMenu = $SaveSlotsMenu
@onready var continue_button: Button = $VBoxContainer/Continue
@onready var load_button: Button = $VBoxContainer/Load

func _ready() -> void:
	# Back from a game the crosshair may still be up.
	CursorMode.menu()
	continue_button.pressed.connect(on_continue_pressed)
	$VBoxContainer/NewGame.pressed.connect(on_new_game_pressed)
	load_button.pressed.connect(on_load_pressed)
	$VBoxContainer/Settings.pressed.connect(on_settings_pressed)
	$VBoxContainer/Quit.pressed.connect(on_quit_pressed)
	settings_menu.closed.connect(on_settings_closed)
	save_slots_menu.closed.connect(on_save_slots_closed)
	# Continue only appears once there's something to continue.
	var has_save:= Saves.has_any_save()
	continue_button.visible = has_save
	load_button.disabled = not has_save

## Picks up from the most recent save, auto or manual.
func on_continue_pressed() -> void:
	Saves.load_game(Saves.latest_slot())

func on_new_game_pressed() -> void:
	Saves.new_game()

func on_load_pressed() -> void:
	menu_container.visible = false
	save_slots_menu.open(SaveSlotsMenu.Mode.LOAD)

func on_save_slots_closed() -> void:
	menu_container.visible = true
	
func on_settings_pressed() -> void:
	menu_container.visible = false
	settings_menu.open()

func on_settings_closed() -> void:
	menu_container.visible = true

func on_quit_pressed() -> void:
	get_tree().quit()
