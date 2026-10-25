extends TestBase
var game: Game
var player
var phase := 0
var t0 := 0
var items: ItemDatabase
func _ready() -> void:
	SaveManager.delete_save()
	game = load("res://game/game.tscn").instantiate()
	add_child(game)
func step() -> void:
	match phase:
		0:
			if frames < 20: return
			phase = 1
			player = get_tree().get_first_node_in_group(&"player")
			items = SaveManager.ITEMS
			check(not SaveManager.has_save(), "no save at start")
			# main menu Load is disabled without a save
			var menu = load("res://game/ui/main_menu/main_menu.tscn").instantiate()
			add_child(menu)
			check(menu.load_button.disabled, "main menu Load disabled with no save")
			menu.queue_free()
			var inv: Inventory = player.data.inventory
			inv.add(items.find(&"gold"), 37)
			inv.add(items.find(&"throwing_dagger"), 5)
			inv.add(items.find(&"health_potion"), 2)
			inv.add(items.find(&"apprentice_staff"), 1)
			player.player_equipment_system.try_equip(player.data, items.find(&"apprentice_staff"))
			player.stats.health.set_current(12)
			player.stats.mana.set_current(7)
			game.change_map(&"w1_rest")
			t0 = frames
		1:
			if frames == t0 + 60:
				check(game.current_map_id == &"w1_rest", "moved to the rest area")
				player.global_position = Vector2(300, 250)
				check(SaveManager.save_game(), "saved")
				check(SaveManager.has_save(), "save file exists")
				var d := SaveManager.read_save()
				check(d.get("map_id") == "w1_rest", "map saved")
				check(String(d.get("map_name")).contains("Rest"), "map name saved (%s)" % d.get("map_name"))
				check(SaveManager.describe_save().begins_with("World 1"), "describe: %s" % SaveManager.describe_save())
				var menu = load("res://game/ui/main_menu/main_menu.tscn").instantiate()
				add_child(menu)
				check(not menu.load_button.disabled, "main menu Load enabled with a save")
				menu.queue_free()
				# simulate a fresh launch + Load: drop this game, start another from the save
				SaveManager._pending = SaveManager.read_save()
				game.queue_free()
				t0 = frames; phase = 2
		2:
			if frames == t0 + 2:
				game = load("res://game/game.tscn").instantiate()
				add_child(game)
			if frames == t0 + 20:
				player = get_tree().get_first_node_in_group(&"player")
				var inv: Inventory = player.data.inventory
				check(game.current_map_id == &"w1_rest", "loaded into the saved map")
				check(player.global_position.distance_to(Vector2(300, 250)) < 1.0, "position restored (%s)" % player.global_position)
				check(inv.get_count(&"gold") == 37 and inv.get_count(&"throwing_dagger") == 5 and inv.get_count(&"health_potion") == 2, "inventory restored")
				check(player.data.equipment.get_item(EquippableItem.Slot.WEAPON) == items.find(&"apprentice_staff"), "staff re-equipped")
				check(player.stats.mana.maximum == 20, "equipment bonus re-applied (max mana %d)" % player.stats.mana.maximum)
				# Mana regenerates 1/s, so it may have ticked once since the load.
				check(player.stats.health.current == 12 and player.stats.mana.current in [7, 8], "stats restored (hp %d, mana %d)" % [player.stats.health.current, player.stats.mana.current])
				check(player.data.current_spell_attack == &"spell_fireball", "spells back with the staff")
				# corrupt save is refused, not crashed on
				var f := FileAccess.open(SaveManager.save_path, FileAccess.WRITE); f.store_string("{not json"); f.close()
				check(SaveManager.read_save().is_empty(), "corrupt save refused")
				check(not SaveManager.load_game(), "load_game refuses it")
				SaveManager.delete_save()
				finish("SAVE")
