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
			# pure math
			var s := StatSystem.new(Stat.new(1000))
			s.armor = 10
			check(is_equal_approx(s.mitigate(10.0), 5.0), "10 armor halves damage")
			s.armor = 30
			var total := 0
			for i in 100: total += s.take_damage(1.0)
			check(total == 25, "1-damage hits through 30 armor still land a quarter (%d/100)" % total)
			s.armor = 0
			check(s.take_damage(7.0) == 7, "no armor = full damage")
			# helmet
			var helm: EquippableItem = SaveManager.ITEMS.find(&"iron_helm")
			check(helm != null and helm.slot == EquippableItem.Slot.HEAD, "iron helm in the database, HEAD slot")
			check(player.stats.armor == 0, "player starts with 0 armor")
			player.data.inventory.add(helm, 1)
			var sword: EquippableItem = SaveManager.ITEMS.find(&"iron_sword")
			player.data.inventory.add(sword, 1)
			player.player_equipment_system.try_equip(player.data, sword)
			check(player.player_equipment_system.try_equip(player.data, helm), "helm equips")
			check(player.data.equipment.get_item(EquippableItem.Slot.WEAPON) == sword, "helm doesn't displace the weapon")
			check(player.stats.armor == 3, "helm gives 3 armor")
			var hud_text: String = game.get_node("Hud").armor_value.text
			check(hud_text.begins_with("3"), "hud shows armor (%s)" % hud_text)
			var hp0: int = player.stats.health.current
			player._on_damage_received(10.0, false)
			check(hp0 - player.stats.health.current == 7, "10 damage through 3 armor = 7 (%d)" % (hp0 - player.stats.health.current))
			# grunt armor
			var grunt = spawn_enemy(GRUNT, Vector2(-3000, 3000))
			t0 = frames; phase = 2
			set_meta("grunt", grunt)
		2:
			if frames == t0 + 2:
				var grunt = get_meta("grunt")
				check(grunt.stats.armor == 3, "grunts have 3 armor")
				# save with helm worn, reload into a fresh game
				check(SaveManager.save_game(), "saved")
				SaveManager._pending = SaveManager.read_save()
				game.queue_free()
			if frames == t0 + 4:
				game = load("res://game/game.tscn").instantiate()
				add_child(game)
			if frames == t0 + 25:
				player = get_tree().get_first_node_in_group(&"player")
				check(player.data.equipment.get_item(EquippableItem.Slot.HEAD) == SaveManager.ITEMS.find(&"iron_helm"), "helm still worn after load")
				check(player.stats.armor == 3, "armor restored from gear (%d)" % player.stats.armor)
				SaveManager.delete_save()
				finish("ARMOR")
