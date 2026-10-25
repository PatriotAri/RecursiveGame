extends TestBase
## Walks the whole of World 1 through its doors: every level's rounds,
## every rest area, the completion room, and the exit to the menu.
var game: Game
var player
var phase := 0
var t0 := 0
var route := [&"w1_level_1", &"w1_rest", &"w1_level_2", &"w1_rest_2", &"w1_level_3", &"w1_rest_3", &"w1_complete"]
var step_i := 0
func _ready() -> void:
	_reparent.call_deferred()
func _reparent() -> void:
	# At the root so the final change to the main menu doesn't free the test.
	var root := get_tree().root
	var tree := get_tree()
	get_parent().remove_child(self)
	root.add_child(self)
	game = load("res://game/game.tscn").instantiate()
	root.add_child(game)
	tree.current_scene = game
func tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)
func kill_all() -> void:
	for e in get_tree().get_nodes_in_group(&"enemy"):
		if not e.data.is_dead:
			e.get_node("Hurtbox").receive_damage(999, player.get_node("Hurtbox"), false, false)
func use_door(door: Node2D) -> void:
	# Stand on the walkable side of the door, then press E.
	var map: Map = game.current_map
	var best := door.global_position
	for d in [Vector2(-64, 0), Vector2(64, 0), Vector2(0, -64), Vector2(0, 64)]:
		var p: Vector2 = door.global_position + d
		var walls: TileMapLayer = map.get_node("Walls")
		if walls.get_cell_source_id(walls.local_to_map(walls.to_local(p))) == -1 and map.get_node("Ground").get_cell_source_id(map.get_node("Ground").local_to_map(p)) != -1:
			best = door.global_position + d * 0.75
	player.global_position = best
	await get_tree().physics_frame
	await get_tree().physics_frame
	tap("interact")
var started := false
func step() -> void:
	if not started:
		if game == null: return
		started = true
	match phase:
		0:
			if frames < 30: return
			player = get_tree().get_first_node_in_group(&"player")
			phase = 1; t0 = frames
		1:
			# arrive somewhere on the route
			if frames < t0 + 40: return
			var expected: StringName = route[step_i]
			check(game.current_map_id == expected, "reached %s (%s)" % [expected, game.current_map_id])
			if game.current_map_id != expected:
				finish("CAMPAIGN"); phase = 9; return
			var rm: RoundManager = game.current_map.get_round_manager()
			if rm:
				while rm.can_start():
					rm.start_round()
					# drain staggered spawns immediately
					for s in get_tree().get_nodes_in_group(&"enemy_spawner"):
						while s.pending_count() > 0:
							s._queued -= 1; s._spawn_one()
					kill_all()
				check(rm.is_finished(), "%s: all %d rounds cleared" % [expected, rm.total_rounds])
			phase = 2; t0 = frames
		2:
			if frames == t0 + 5:
				if step_i == route.size() - 1:
					var exit = game.current_map.get_node("Y-sorted/MenuExit")
					player.global_position = exit.global_position + Vector2(0, 10)
					t0 = frames; phase = 3
					return
				var door: Door = null
				for n in ["ExitDoor", "OnwardDoor"]:
					door = game.current_map.get_node_or_null("Y-sorted/" + n)
					if door: break
				check(door != null and not door.is_locked(), "%s: way on is open" % route[step_i])
				use_door(door)
			if frames == t0 + 70:
				step_i += 1
				phase = 1; t0 = frames - 40
		3:
			if frames == t0 + 3: tap("interact")
			if frames == t0 + 15:
				check(get_tree().current_scene != null and get_tree().current_scene.scene_file_path == "res://main.tscn", "menu exit returns to the main menu")
				finish("CAMPAIGN"); phase = 9
