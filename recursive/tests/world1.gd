extends TestBase
var game: Game
var player
var rm: RoundManager
var phase := 0
var t0 := 0
var seen := {}
var exit_door: Door
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	add_child(game)
func tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)
func kill_all() -> void:
	for e in get_tree().get_nodes_in_group(&"enemy"):
		if not e.data.is_dead:
			e.get_node("Hurtbox").receive_damage(999, player.get_node("Hurtbox"), false, false)
func step() -> void:
	match phase:
		0:
			if frames < 20: return
			phase = 1
			player = get_tree().get_first_node_in_group(&"player")
			check(game.current_map_id == &"w1_level_1", "game starts in World 1 Level 1")
			check(player.global_position == Vector2(288, 352), "player in the entry room")
			rm = game.current_map.get_round_manager()
			check(rm.total_rounds == 4, "4 rounds")
			exit_door = game.current_map.get_node("Y-sorted/ExitDoor")
			check(exit_door.is_locked(), "exit locked at the start")
			var nav_map: RID = player.get_world_2d().navigation_map
			var path := NavigationServer2D.map_get_path(nav_map, Vector2(288, 352), Vector2(1600, 416), true)
			check(path.is_empty() or path[-1].distance_to(Vector2(1600, 416)) > 64, "arena unreachable while the door is shut")
			# open the arena door
			player.global_position = Vector2(480, 416)
			t0 = frames
		1:
			if frames == t0 + 3: tap("interact")
			if frames == t0 + 10:
				var door: Door = game.current_map.get_node("Y-sorted/ArenaDoor")
				check(door.is_open, "arena door opens")
				var nav_map: RID = player.get_world_2d().navigation_map
				var path := NavigationServer2D.map_get_path(nav_map, Vector2(288, 352), Vector2(1600, 416), true)
				check(path.size() > 0 and path[-1].distance_to(Vector2(1600, 416)) < 8, "arena reachable through the door")
				player.global_position = Vector2(672, 440)
			if frames == t0 + 14:
				var f: Interactable = player.player_interaction_system.focused()
				check(f != null and f.get_parent() is RoundButton, "round button in reach")
				tap("interact")
				t0 = frames; phase = 2
		2:
			# play the four rounds, recording which types show up
			for e in get_tree().get_nodes_in_group(&"enemy"):
				seen[e.get_script().get_global_name()] = true
			if (frames - t0) % 40 == 39:
				kill_all()
			if not rm.active and rm.current_round < 4 and (frames - t0) % 40 == 0 and frames > t0 + 5:
				rm.start_round()
			if rm.is_finished():
				# Which type each spawn rolls is random, so assert on what the
				# spawners can produce by the last round, and that every spawn
				# came from that mix — not on which rolls happened to land.
				var eligible := {}
				for sp in get_tree().get_nodes_in_group(&"enemy_spawner"):
					for entry in sp.entries:
						if entry and entry.scene and entry.min_round <= rm.total_rounds:
							var probe: Node = entry.scene.instantiate()
							eligible[probe.get_script().get_global_name()] = true
							probe.free()
				check(eligible.has("Crawler") and eligible.has("Spitter") and eligible.has("Bat") and eligible.has("Grunt"), "all four types in the arena's mix: %s" % str(eligible.keys()))
				var stray := seen.keys().filter(func(k): return not eligible.has(k))
				check(seen.size() >= 2 and stray.is_empty(), "spawns mixed and all from the mix: %s" % str(seen.keys()))
				check(not exit_door.is_locked(), "exit unlocks after the last round")
				player.global_position = Vector2(1830, 416)
				t0 = frames; phase = 3
			if frames > t0 + 2000:
				check(false, "rounds finished in time"); finish("WORLD1")
		3:
			if frames == t0 + 3: tap("interact")
			if frames == t0 + 60:
				check(game.current_map_id == &"w1_rest", "exit leads to the rest area")
				check(game.current_map.get_node_or_null("Y-sorted/Shop") != null, "rest area has a shop")
				var onward: Door = game.current_map.get_node("Y-sorted/OnwardDoor")
				check(not onward.is_locked() and onward.target_map == &"w1_level_2", "onward door leads to Level 2")
				finish("WORLD1")
