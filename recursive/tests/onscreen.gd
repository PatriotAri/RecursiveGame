extends TestBase
var game: Game
var near; var far
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"test_level_01"
	add_child(game)
func step() -> void:
	if frames == 20:
		var p = get_tree().get_first_node_in_group(&"player")
		near = spawn_enemy(CRAWLER, p.global_position + Vector2(60, 0))
		far = spawn_enemy(CRAWLER, p.global_position + Vector2(2000, 0))
	if frames == 40:
		if DisplayServer.get_name() == "headless":
			check(near._on_screen and far._on_screen, "headless: off-screen pausing disabled (nothing renders)")
			finish("ONSCREEN"); return
		print("near on_screen=", near._on_screen, " playing=", near.sprite.is_playing(), " | far on_screen=", far._on_screen, " playing=", far.sprite.is_playing())
		check(near._on_screen and near.sprite.is_playing(), "enemy in view animates")
		check(not far._on_screen and not far.sprite.is_playing(), "enemy out of view paused")
		finish("ONSCREEN")
