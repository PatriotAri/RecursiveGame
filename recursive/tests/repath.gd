extends TestBase
## An enemy already routing round a wall takes a door the moment it opens,
## though the player (its target) never moves.
var game: Game
var player
var e
var phase := 0
var t0 := 0
var went_through := false
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"test_level_01"
	add_child(game)
func step() -> void:
	match phase:
		0:
			if frames < 30: return
			player = get_tree().get_first_node_in_group(&"player")
			player.set_physics_process(false)
			player.global_position = Vector2(430, -160)
			e = spawn_enemy(CRAWLER, Vector2(280, -160))
			e.profile = e.profile.duplicate()
			e.profile.flee_health_ratio = 0.0
			phase = 1; t0 = frames
		1:
			if frames == t0 + 40:
				var next: Vector2 = e.navigation.next_path_position(player.global_position)
				check(absf(next.y + 160) > 60, "door shut: heading round the wall end (next %s)" % next)
				game.current_map.get_node("Y-sorted/InteriorDoor").open()
			if frames > t0 + 40 and absf(e.global_position.x - 352) < 20 and absf(e.global_position.y + 160) < 40:
				went_through = true
			if frames == t0 + 300:
				check(went_through, "rerouted through the opened door (now at %s)" % e.global_position)
				finish("REPATH")
