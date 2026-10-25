extends TestBase
var game: Node
var player
var enemies: Array
var a; var b
var phase := 0
var t0 := 0
var min_dist := INF
var went_around := false
var flee_d0 := 0.0
var saw_flee := false
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"test_level_01"
	add_child(game)
func park_all() -> void:
	var i := 0
	for e in get_tree().get_nodes_in_group(&"enemy"):
		e.global_position = Vector2(-3000 - i * 100, 3000); i += 1
func step() -> void:
	match phase:
		0:
			if frames < 20: return
			# Wait for the navmesh rather than assume a frame count.
			var probe := get_tree().get_nodes_in_group(&"enemy")
			if probe.is_empty():
				spawn_enemy(CRAWLER, Vector2(-3000, 3000))
				spawn_enemy(CRAWLER, Vector2(-3100, 3000))
				return
			if not probe[0].navigation.has_navigation() and frames < 300: return
			phase = 1
			player = get_tree().get_first_node_in_group(&"player")
			enemies = get_tree().get_nodes_in_group(&"enemy")
			a = enemies[0]; b = enemies[1]
			var nav = game.current_map.get_node("Navigation")
			var m: RID = a.navigation.agent.get_navigation_map()
			print("  DIAG proc_frames=%d iter=%d polys=%d regions=%d agent_map==region_map=%s owner_valid=%s" % [Engine.get_process_frames(), NavigationServer2D.map_get_iteration_id(m), nav.navigation_polygon.get_polygon_count() if nav.navigation_polygon else -1, NavigationServer2D.map_get_regions(m).size(), m == nav.get_navigation_map(), NavigationServer2D.map_get_closest_point_owner(m, Vector2(300, 0)).is_valid()])
			check(a.navigation.has_navigation(), "navmesh baked")
			# point inside the vertical wall (cell x=5 -> 320..384)
			var inside := Vector2(352, -192)
			var snapped: Vector2 = a.navigation.closest_walkable(inside)
			check(snapped.distance_to(inside) > 20, "closest_walkable leaves the wall (%s)" % snapped)
			park_all()
			player.set_physics_process(false)
			player.global_position = Vector2(420, -192)
			a.global_position = Vector2(296, -192)
			t0 = frames
		1:
			min_dist = minf(min_dist, a.global_position.distance_to(player.global_position))
			if a.global_position.y < -330 or a.global_position.y > -50: went_around = true
			check_once_wall()
			if (frames - t0) % 30 == 0 and frames - t0 <= 300:
				print("  t=%d state=%s pos=%s det=%s next=%s vel=%s" % [frames - t0, EnemyData.State.keys()[a.data.current_state], a.global_position.round(), a.data.player_detected, a.navigation.next_path_position(player.global_position).round(), a.velocity.round()])
			if frames == t0 + 600:
				check(went_around, "chaser routed round the wall end")
				check(min_dist < 40, "chaser reached the player (closest %.0f)" % min_dist)
				# spacing: stack two on one spot
				park_all()
				player.global_position = Vector2(-500, 400)
				a.global_position = Vector2(-200, -300); b.global_position = Vector2(-200, -300)
				a.data.player_detected = false; b.data.player_detected = false
				t0 = frames; phase = 2
		2:
			if frames == t0 + 60:
				var d: float = a.global_position.distance_to(b.global_position)
				check(d > 15, "stacked enemies spread apart (%.1f px)" % d)
				# flee: wound a crawler near the player
				park_all()
				player.global_position = Vector2(-100, 100)
				a.global_position = Vector2(-40, 100)
				a.stats.health.remove(6)   # 4/10 = 0.4 <= 0.5
				t0 = frames; phase = 3
		3:
			if a.data.current_state == EnemyData.State.FLEE:
				if not saw_flee: flee_d0 = a.global_position.distance_to(player.global_position)
				saw_flee = true
			if frames == t0 + 90:
				check(saw_flee, "wounded crawler flees")
				var d: float = a.global_position.distance_to(player.global_position)
				check(d > flee_d0 + 30, "fled away (%.0f -> %.0f)" % [flee_d0, d])
				# dagger into a wall: border wall at x=9 cell -> 576
				park_all()
				player.set_physics_process(true)
				player.global_position = Vector2(400, 300)
				var dagger = load("res://game/items/equipment/weapons/tier_1/throwing_dagger/throwing_dagger.tres")
				player.data.inventory.add(dagger, 2)
				player.player_equipment_system.try_equip(player.data, dagger)
				player.data.facing_dir = Vector2.RIGHT
				Input.action_press("player_attack")
				t0 = frames; phase = 4
		4:
			if frames == t0 + 2: Input.action_release("player_attack")
			if frames == t0 + 40:
				# 380 px/s * ~0.5s = 190 px max travel; wall at 576-ish is ~150 px away
				var any := false
				for n in player.get_parent().get_children():
					if n is Projectile: any = true
				check(not any, "dagger stopped at the wall before max range")
				finish("AI")
var _wall_checked := false
func check_once_wall() -> void:
	if _wall_checked: return
	_wall_checked = true
	# straight line from a to player must cross the wall: sanity
	var space = player.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(a.global_position, player.global_position, 1)
	check(not space.intersect_ray(q).is_empty(), "wall blocks the straight line")
