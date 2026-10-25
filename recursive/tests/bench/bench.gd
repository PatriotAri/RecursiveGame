extends TestBase
## Physics-frame cost with N crawlers chasing the player. Arg: N
var game: Game
var player
var n := 50
var samples: Array[float] = []
var t0 := 0
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: n = int(a[0])
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"w1_level_1"
	add_child(game)
func step() -> void:
	if frames == 30:
		player = get_tree().get_first_node_in_group(&"player")
		player.global_position = Vector2(1200, 420)
		player.stats.health.maximum = 1000000; player.stats.health.set_current(1000000)
		for i in n:
			var a := TAU * i / n
			var e = spawn_enemy(CRAWLER, Vector2(1200, 420) + Vector2(cos(a), sin(a) * 0.6) * (120 + (i % 5) * 30))
			e.profile = e.profile.duplicate()
			e.profile.flee_health_ratio = 0.0
		t0 = frames
	if frames > t0 + 60 and frames <= t0 + 360 and t0 > 0:
		samples.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	if t0 > 0 and frames == t0 + 361:
		samples.sort()
		var avg := 0.0
		for s in samples: avg += s
		avg /= samples.size()
		print("N=%d physics avg %.2f ms  p95 %.2f ms  objects=%d nodes=%d" % [n, avg, samples[int(samples.size() * 0.95)], Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
		get_tree().quit()
