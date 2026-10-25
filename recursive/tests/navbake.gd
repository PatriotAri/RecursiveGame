extends TestBase
var game: Game
var nav: LevelNavigation
var door: Door
var t0 := 0
var done_at := -1
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	add_child(game)
func step() -> void:
	if frames == 30:
		nav = game.current_map.get_node("Navigation")
		nav.bake_finished.connect(func(): done_at = frames; print("bake_finished at +", frames - t0))
		door = game.current_map.get_node("Y-sorted/ArenaDoor")
		var t := Time.get_ticks_usec()
		for i in 10: nav.bake()
		print("sync bake avg: %.2f ms" % ((Time.get_ticks_usec() - t) / 10000.0))
		door.open(); t0 = frames
	if frames > 30 and frames <= t0 + 120 and (frames - t0) % 10 == 0:
		var m: RID = nav.get_navigation_map()
		var path := NavigationServer2D.map_get_path(m, Vector2(288, 352), Vector2(1600, 416), true)
		print("+%d baking=%s path_end=%s regions=%d" % [frames - t0, nav.is_baking(), path[-1] if path.size() else "none", NavigationServer2D.map_get_regions(m).size()])
	if frames == t0 + 121: finish("NAVBAKE")
