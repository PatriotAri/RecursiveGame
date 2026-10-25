extends TestBase
var game: Game
var player
var rm: RoundManager
var phase := 0
var t0 := 0
var gold: Item
var potion: Item
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"test_level_01"
	add_child(game)
func tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)
func label() -> String:
	return game.get_node("Hud").round_label.text
func kill_all() -> void:
	for e in get_tree().get_nodes_in_group(&"enemy"):
		if not e.data.is_dead:
			e.get_node("Hurtbox").receive_damage(999, player.get_node("Hurtbox"), false, false)
func in_wall(pos: Vector2) -> bool:
	var walls: TileMapLayer = game.current_map.get_node("Walls")
	return walls.get_cell_source_id(walls.local_to_map(walls.to_local(pos))) != -1
func step() -> void:
	match phase:
		0:
			if frames < 20: return
			phase = 1
			player = get_tree().get_first_node_in_group(&"player")
			check(game.current_map_id == &"test_level_01", "starting map loaded")
			check(player.get_parent() == game.current_map.get_entity_root(), "player lives in the map's entity root")
			check(player.global_position == Vector2(80, 0), "placed at Default spawn")
			check(get_tree().get_nodes_in_group(&"enemy").is_empty(), "no enemies before the round")
			rm = game.current_map.get_round_manager()
			check(rm != null and rm.total_rounds == 3, "map has a 3-round manager")
			check(label() == "Start the round when ready", "hud: ready (%s)" % label())
			player.global_position = Vector2(160, 60)
			t0 = frames
		1:
			if frames == t0 + 3:
				var f: Interactable = player.player_interaction_system.focused()
				check(f != null and f.get_parent() is RoundButton, "round button focused")
				check(f != null and f.prompt == "Start Round 1", "prompt: %s" % (f.prompt if f else "none"))
				tap("interact")
			if frames == t0 + 8:
				check(rm.active and rm.current_round == 1, "E started round 1")
				var enemies := get_tree().get_nodes_in_group(&"enemy")
				check(enemies.size() == 4, "round 1 spawned 4 (%d)" % enemies.size())
				var bad := 0
				for e in enemies:
					if not (e is Bat) and in_wall(e.global_position): bad += 1
				check(bad == 0, "no walker spawned inside a wall")
				check(label().begins_with("Round 1/3"), "hud: %s" % label())
				var door: Door = game.current_map.get_node("Y-sorted/InteriorDoor")
				check(door.is_locked(), "door locked during the round")
				check(not player.player_interaction_system.focused(), "button not usable mid-round")
				kill_all()
			if frames == t0 + 12:
				check(not rm.active, "round ends when all are dead")
				check(label() == "Round 1 cleared", "hud: %s" % label())
				var door: Door = game.current_map.get_node("Y-sorted/InteriorDoor")
				check(not door.is_locked(), "door unlocked after")
				# open the interior door
				player.global_position = Vector2(290, -160)
				t0 = frames; phase = 2
		2:
			if frames == t0 + 3:
				var f: Interactable = player.player_interaction_system.focused()
				check(f != null and f.get_parent() is Door, "door focused (%s)" % (f.get_parent().name if f else "none"))
				tap("interact")
			if frames == t0 + 12:
				var door: Door = game.current_map.get_node("Y-sorted/InteriorDoor")
				check(door.is_open and door.collision.disabled, "door opened")
				var map_rid: RID = player.get_world_2d().navigation_map
				var path := NavigationServer2D.map_get_path(map_rid, Vector2(250, -160), Vector2(450, -160), true)
				var max_dev := 0.0
				for pt in path: max_dev = maxf(max_dev, absf(pt.y + 160))
				check(path.size() > 0 and max_dev < 40, "navmesh now goes through the door (dev %.0f)" % max_dev)
				# go to the shop
				gold = load("res://game/items/drops/gold_sack/gold.tres")
				potion = load("res://game/items/consumables/potions/health_potion/health_potion.tres")
				player.data.inventory.add(gold, 40)
				player.global_position = Vector2(32, -425)
				t0 = frames; phase = 3
		3:
			if frames == t0 + 3:
				var f: Interactable = player.player_interaction_system.focused()
				check(f != null and f.prompt == "Enter", "shop passage focused")
				tap("interact")
			if frames == t0 + 60:
				check(game.current_map_id == &"test_shop", "now in the shop map (%s)" % game.current_map_id)
				check(player.global_position == Vector2(32, 210), "arrived at FromLevel")
				check(player.data.inventory.get_count(&"gold") == 40, "inventory carried over")
				check(get_tree().get_nodes_in_group(&"round_manager").is_empty(), "old map's round manager gone")
				player.global_position = Vector2(0, -60)
				t0 = frames; phase = 4
		4:
			if frames == t0 + 3:
				tap("interact")
			if frames == t0 + 8:
				var ui = get_tree().get_first_node_in_group(&"shop_ui")
				check(ui.visible and get_tree().paused, "shop open and game paused")
				var shop: Shop = ui.shop
				check(shop.buy(0, player.data.inventory), "bought a health potion")
				check(player.data.inventory.get_count(&"gold") == 32 and player.data.inventory.get_count(potion.id) == 1, "paid 8 gold")
				check(shop.buy(4, player.data.inventory), "bought the sword (30g)")
				check(not shop.buy(4, player.data.inventory), "sword sold out")
				check(not shop.buy(0, player.data.inventory), "can't afford with 2 gold")
				check(ui.rows.get_child(4).disabled, "sold-out row disabled")
				ui.close()
				check(not get_tree().paused, "closing unpauses")
				player.global_position = Vector2(32, 230)
				t0 = frames; phase = 5
		5:
			if frames == t0 + 3:
				tap("interact")
			if frames == t0 + 60:
				check(game.current_map_id == &"test_level_01", "back in the level")
				check(player.global_position == Vector2(32, -400), "arrived at FromShop")
				rm = game.current_map.get_round_manager()
				# rounds restart with a fresh map; play all three
				rm.start_round(); kill_all()
				t0 = frames; phase = 6
		6:
			if frames == t0 + 3:
				rm.start_round(); kill_all()
			if frames == t0 + 6:
				var grunts := 0
				for e in get_tree().get_nodes_in_group(&"enemy"):
					if e is Grunt: grunts += 1
				rm.start_round()
				var now := 0
				for e in get_tree().get_nodes_in_group(&"enemy"):
					if e is Grunt and not e.data.is_dead: now += 1
				check(now == 2, "round 3 brings 2 grunts (%d)" % now)
				kill_all()
			if frames == t0 + 10:
				check(rm.is_finished(), "all rounds finished")
				check(label() == "All rounds cleared!", "hud: %s" % label())
				check(not rm.start_round(), "no round 4")
				finish("ROUNDS")
