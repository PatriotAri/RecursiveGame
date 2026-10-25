extends TestBase
## Main menu -> Load -> scene change -> saved game. The test node moves itself
## to the root so change_scene_to_file() doesn't free it with the scene.
var phase := 0
var t0 := 0
func _ready() -> void:
	var f := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "saved_at": "x", "map_id": "w1_rest", "map_name": "Rest",
		"player": {"position": [200, 230], "health": 9, "stamina": 20, "mana": 10,
			"inventory": [{"id": "gold", "count": 12}, {"id": "no_such_item", "count": 1}], "equipment": {}}}))
	f.close()
	_move_to_root.call_deferred()
func _move_to_root() -> void:
	var root := get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	get_tree().change_scene_to_file("res://main.tscn")
func step() -> void:
	match phase:
		0:
			if frames < 10: return
			phase = 1
			var menu := get_tree().current_scene.get_node("MainMenu")
			check(not menu.load_button.disabled, "Load enabled")
			menu.load_button.pressed.emit()
			t0 = frames
		1:
			if frames == t0 + 20:
				var game := get_tree().current_scene as Game
				check(game != null, "scene is now the game")
				check(game != null and game.current_map_id == &"w1_rest", "in the saved map")
				var p = get_tree().get_first_node_in_group(&"player")
				check(p != null and p.data.inventory.get_count(&"gold") == 12, "inventory loaded")
				check(p != null and p.stats.health.current == 9, "health loaded")
				SaveManager.delete_save()
				finish("LOADFLOW")
