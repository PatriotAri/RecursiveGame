extends TestBase
## Real flow: main menu -> Play -> game; then return to menu via (a) MenuExit, (b) pause menu.
var phase := 0
var t0 := 0
var mode := "exit"
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: mode = args[0]
	_move.call_deferred()
func _move() -> void:
	var root := get_tree().root
	var tree := get_tree()
	get_parent().remove_child(self)
	root.add_child(self)
	tree.change_scene_to_file("res://main.tscn")
func step() -> void:
	match phase:
		0:
			if frames < 10: return
			get_tree().current_scene.get_node("MainMenu/VBoxContainer/Play").pressed.emit()
			phase = 1; t0 = frames
		1:
			if frames == t0 + 20:
				print("--- in game, returning via ", mode)
				if mode == "exit":
					var game: Game = get_tree().current_scene
					game.change_map(&"w1_complete")
				else:
					var pm = get_tree().get_first_node_in_group(&"pause_menu")
					pm.pause()
					pm._on_main_menu_button_pressed()
					t0 = frames; phase = 3
					return
			if mode == "exit" and frames == t0 + 80:
				var p = get_tree().get_first_node_in_group(&"player")
				p.global_position = get_tree().current_scene.current_map.get_node("Y-sorted/MenuExit").global_position + Vector2(0, 10)
			if mode == "exit" and frames == t0 + 84:
				Input.action_press("interact")
			if mode == "exit" and frames == t0 + 86:
				Input.action_release("interact"); t0 = frames; phase = 3
		3:
			if frames == t0 + 15:
				print("--- scene now: ", get_tree().current_scene.scene_file_path)
				finish("MENUEXIT")
