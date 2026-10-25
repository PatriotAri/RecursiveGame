extends TestBase
## Mouse capture isn't checked: the headless display ignores mouse modes.
var game: Game
var phase := 0
var t0 := 0
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"test_shop"
	add_child(game)
func key(action: String) -> void:
	var ev := InputEventAction.new(); ev.action = action; ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new(); up.action = action; up.pressed = false
	Input.parse_input_event(up)
func g(n: StringName) -> CanvasLayer: return get_tree().get_first_node_in_group(n)
func step() -> void:
	if frames < 20: return
	match phase:
		0:
			check(not get_tree().paused and not Menus.any_open(), "playing: unpaused, nothing open")
			key("inventory"); phase = 1; t0 = frames
		1:
			if frames < t0 + 2: return
			check(g(&"inventory_ui").visible and get_tree().paused, "I opens the inventory and pauses")
			key("pause"); phase = 2; t0 = frames
		2:
			if frames < t0 + 2: return
			check(not g(&"inventory_ui").visible and not get_tree().paused, "Esc closes the inventory, unpauses")
			check(not g(&"pause_menu").visible, "...without opening the pause menu")
			key("pause"); phase = 3; t0 = frames
		3:
			if frames < t0 + 2: return
			check(g(&"pause_menu").visible and get_tree().paused, "Esc with nothing open opens the pause menu")
			key("inventory"); phase = 4; t0 = frames
		4:
			if frames < t0 + 2: return
			check(not g(&"inventory_ui").visible, "inventory won't stack on the pause menu")
			key("pause"); phase = 5; t0 = frames
		5:
			if frames < t0 + 2: return
			check(not g(&"pause_menu").visible and not get_tree().paused, "Esc closes the pause menu")
			var p = get_tree().get_first_node_in_group(&"player")
			g(&"shop_ui").open(game.current_map.get_node("Y-sorted/Shop"), p)
			check(get_tree().paused, "shop pauses")
			g(&"death_screen").show_death()
			key("pause"); phase = 6; t0 = frames
		6:
			if frames < t0 + 2: return
			check(g(&"death_screen").visible, "Esc can't close the death screen")
			check(g(&"shop_ui").visible and get_tree().paused, "still paused underneath")
			g(&"shop_ui").close()
			check(get_tree().paused, "closing the shop keeps the pause while the death screen is up")
			Menus.reset()
			check(not get_tree().paused, "reset unpauses")
			finish("MENUS")
