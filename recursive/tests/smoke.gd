extends TestBase
# Loads the game, pulls a crawler onto the player, checks it fights, then kills it.
var game: Node
var player
var enemy
var start_hp := 0
var phase := 0
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"test_level_01"
	add_child(game)
func step() -> void:
	match phase:
		0:
			if frames < 30: return
			phase = 1
			player = get_tree().get_first_node_in_group(&"player")
			spawn_enemy(CRAWLER, player.global_position + Vector2(300, 0))
			spawn_enemy(CRAWLER, player.global_position + Vector2(-300, 0))
			var enemies := get_tree().get_nodes_in_group(&"enemy")
			check(player != null, "player exists")
			check(enemies.size() > 0, "enemies spawned (%d)" % enemies.size())
			enemy = enemies[0]
			check(enemy is Enemy, "enemy is Enemy")
			for e in enemies:
				if e != enemy: e.global_position = Vector2(5000, 5000)
			enemy.global_position = player.global_position + Vector2(20, 0)
			start_hp = player.stats.health.current
		1:
			if frames < 300: return
			phase = 2
			print("enemy state: ", EnemyData.State.keys()[enemy.data.current_state])
			check(player.stats.health.current < start_hp, "player took damage (%d -> %d)" % [start_hp, player.stats.health.current])
			enemy.get_node("Hurtbox").receive_damage(999, player.get_node("Hurtbox"), true, true)
		2:
			if frames < 420: return
			phase = 3
			check(not is_instance_valid(enemy), "enemy freed after death")
			finish("SMOKE")
