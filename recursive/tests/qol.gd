extends TestBase
var game: Game
var player
var phase := 0
var t0 := 0
func _ready() -> void:
	SaveManager.delete_save()
	game = load("res://game/game.tscn").instantiate()
	add_child(game)
func step() -> void:
	match phase:
		0:
			if frames < 30: return
			phase = 1
			player = get_tree().get_first_node_in_group(&"player")
			var b: Rect2 = game.current_map.get_bounds()
			check(b.size == Vector2(30 * 64, 14 * 64), "level 1 bounds = whole tile grid (%s)" % b)
			check(player.camera.limit_left == 0 and player.camera.limit_right == 30 * 64, "camera limited to the map")
			check(not SaveManager.has_save(), "no autosave in a fight level")
			var door: Door = game.current_map.get_node("Y-sorted/ArenaDoor")
			check(door.interactable._label.text.begins_with("[E] "), "prompt shows bound key (%s)" % door.interactable._label.text)
			# rebind interact to F and check the prompt follows
			var ev := InputEventKey.new(); ev.physical_keycode = KEY_F
			InputMap.action_erase_events(&"interact"); InputMap.action_add_event(&"interact", ev)
			door.interactable.set_prompt("Open")
			check(door.interactable._label.text.begins_with("[F] "), "prompt follows a rebind (%s)" % door.interactable._label.text)
			InputMap.load_from_project_settings()
			game.change_map(&"w1_rest")
			t0 = frames
		1:
			if frames == t0 + 60:
				check(game.current_map_id == &"w1_rest", "in rest area")
				check(SaveManager.has_save() and SaveManager.read_save().get("map_id") == "w1_rest", "autosaved on entering the rest area")
				check(game.get_node("Hud").toast.modulate.a > 0.5, "toast showing")
				check(player.camera.limit_right == 12 * 64, "camera limits follow the map (%d)" % player.camera.limit_right)
				SaveManager.delete_save()
				finish("QOL")
