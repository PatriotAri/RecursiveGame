extends TestBase
## Performance budget. Physics cost with 50 crawlers on the player, then 200,
## in one run. The main check is the ratio: it compares this machine with
## itself, so a slow CI runner doesn't fail it. Linear scaling is about 4x;
## a return to pairwise (n^2) spacing or collision is well over 8x. The
## absolute cap is loose on purpose and only catches gross regressions.
## Args: [cap_ms_at_200] (default 100)
const SMALL := 50
const LARGE := 200
const MAX_RATIO := 8.0
const SETTLE := 60
const SAMPLE := 240
var cap_ms := 100.0
var game: Game
var player
var spawned := 0
var t0 := -1
var phase := 0
var samples: Array[float] = []
var small_ms := 0.0
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: cap_ms = float(a[0])
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"w1_level_1"
	add_child(game)
func _spawn_up_to(count: int) -> void:
	while spawned < count:
		var i := spawned
		var a := TAU * i / LARGE
		var e = spawn_enemy(CRAWLER, Vector2(1200, 420) + Vector2(cos(a), sin(a) * 0.6) * (120 + (i % 5) * 30))
		e.profile = e.profile.duplicate()
		e.profile.flee_health_ratio = 0.0
		spawned += 1
func _median() -> float:
	samples.sort()
	var m := samples[samples.size() / 2]
	samples.clear()
	return m
func step() -> void:
	if frames == 30:
		player = get_tree().get_first_node_in_group(&"player")
		player.global_position = Vector2(1200, 420)
		player.stats.health.maximum = 1000000; player.stats.health.set_current(1000000)
		_spawn_up_to(SMALL)
		t0 = frames
	if t0 < 0: return
	var since := frames - t0
	if since > SETTLE and since <= SETTLE + SAMPLE:
		samples.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	if since == SETTLE + SAMPLE + 1:
		if phase == 0:
			small_ms = _median()
			_spawn_up_to(LARGE)
			t0 = frames; phase = 1
		else:
			var large_ms := _median()
			var ratio := large_ms / maxf(small_ms, 0.001)
			print("median physics: %d enemies %.2f ms, %d enemies %.2f ms, ratio %.2f" % [SMALL, small_ms, LARGE, large_ms, ratio])
			check(ratio < MAX_RATIO, "scales roughly linearly (%dx enemies -> %.2fx cost, limit %.1fx)" % [LARGE / SMALL, ratio, MAX_RATIO])
			check(large_ms < cap_ms, "%d enemies under %.0f ms per physics frame (%.2f ms)" % [LARGE, cap_ms, large_ms])
			finish("PERF")
