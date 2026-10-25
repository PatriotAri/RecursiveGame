extends TestBase
var game: Node
var player
var spitter; var bat; var grunt
var phase := 0
var t0 := 0
var hp0 := 0
var d0 := 0.0
var saw_glob := false
var bat_min := INF
var bat_crossed_wall := false
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"test_level_01"
	add_child(game)
func park_all() -> void:
	var i := 0
	for e in get_tree().get_nodes_in_group(&"enemy"):
		e.global_position = Vector2(-3000 - i * 200, 3000); i += 1
		e.data.player_detected = false
func first(cls) -> Node:
	for e in get_tree().get_nodes_in_group(&"enemy"):
		if is_instance_of(e, cls): return e
	return null
func step() -> void:
	match phase:
		0:
			if frames < 20: return
			phase = 1
			player = get_tree().get_first_node_in_group(&"player")
			spitter = spawn_enemy(SPITTER, Vector2(-3000, 3000))
			bat = spawn_enemy(BAT, Vector2(-3200, 3000))
			grunt = spawn_enemy(GRUNT, Vector2(-3400, 3000))
			check(spitter is Spitter and bat is Bat and grunt is Grunt, "all three types spawn")
			check(spitter is Enemy and bat is Enemy and grunt is Enemy, "all extend Enemy")
			park_all()
			player.set_physics_process(false)
			player.global_position = Vector2(-100, 0)
			spitter.global_position = Vector2(-240, 0)
			hp0 = player.stats.health.current
			t0 = frames
		1:
			for n in player.get_parent().get_children():
				if n is Projectile and n.thrower == spitter: saw_glob = true
			if frames == t0 + 120:
				check(saw_glob, "spitter fired a projectile")
				check(player.stats.health.current < hp0, "acid hit the player (%d -> %d)" % [hp0, player.stats.health.current])
				# too close: should back off during cooldown
				spitter.global_position = player.global_position + Vector2(-50, 0)
				d0 = 50.0
				t0 = frames; phase = 2
		2:
			if frames == t0 + 90:
				var d: float = spitter.global_position.distance_to(player.global_position)
				check(d > d0 + 20, "spitter backed off (50 -> %.0f)" % d)
				# behind a wall: no line of sight, no shot
				park_all()
				player.global_position = Vector2(420, -192)
				spitter.global_position = Vector2(280, -192)
				spitter.data.attack_cooldown_timer = 0.0
				t0 = frames; phase = 3
		3:
			if frames == t0 + 5:
				check(not spitter.data.in_attack_range, "no line of sight through a wall")
				# bat: chase straight across the wall
				park_all()
				player.global_position = Vector2(420, -192)
				bat.global_position = Vector2(270, -192)
				hp0 = player.stats.health.current
				t0 = frames; phase = 4
		4:
			bat_min = minf(bat_min, bat.global_position.distance_to(player.global_position))
			if bat.global_position.x > 320 and bat.global_position.x < 384 and absf(bat.global_position.y + 192) < 60:
				bat_crossed_wall = true
			if frames == t0 + 240:
				check(bat_crossed_wall, "bat flew over the wall")
				check(bat_min < 40, "bat reached player (closest %.0f)" % bat_min)
				check(player.stats.health.current < hp0, "bat hit the player")
				check(String(bat.sprite.animation) in ["idle", "attack", "hurt"], "bat uses fallback animations (%s)" % bat.sprite.animation)
				# grunt: tanky, doesn't flee
				park_all()
				player.global_position = Vector2(-100, 0)
				grunt.global_position = Vector2(-140, 0)
				check(grunt.stats.health.maximum == 30, "grunt has 30 hp")
				grunt.stats.health.remove(25)
				hp0 = player.stats.health.current
				t0 = frames; phase = 5
		5:
			if frames > t0 + 2:
				if grunt.data.current_state == EnemyData.State.FLEE:
					check(false, "grunt never flees"); finish("TYPES"); phase = 9; return
			if frames == t0 + 150:
				check(true, "grunt never flees")
				var lost: int = hp0 - player.stats.health.current
				check(lost >= 3, "grunt hits hard (lost %d)" % lost)
				finish("TYPES")
