extends TestBase
var game: Node
var player
var enemy
var dagger: EquippableItem
var phase := 0
var t0 := 0
var proj: Projectile
var first_proj: Projectile
var hp0 := 0
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"test_level_01"
	add_child(game)
func _press() -> void:
	Input.action_press("player_attack")
func _release() -> void:
	Input.action_release("player_attack")
func _find_proj() -> Projectile:
	for n in player.get_parent().get_children():
		if n is Projectile and not n.is_released(): return n
	return null
func step() -> void:
	match phase:
		0:
			if frames < 20: return
			player = get_tree().get_first_node_in_group(&"player")
			spawn_enemy(CRAWLER, Vector2(-3000, 3000))
			spawn_enemy(CRAWLER, Vector2(-3100, 3000))
			var enemies := get_tree().get_nodes_in_group(&"enemy")
			enemy = enemies[0]
			for e in enemies:
				if e != enemy: e.global_position = Vector2(5000, 5000)
			# Out of the crawler's detection (160) so it stays put: 200px right.
			enemy.global_position = player.global_position + Vector2(200, 0)
			enemy.set_physics_process(false)
			dagger = load("res://game/items/equipment/weapons/tier_1/throwing_dagger/throwing_dagger.tres")
			player.data.inventory.add(dagger, 2)
			check(player.player_equipment_system.try_equip(player.data, dagger), "equipped daggers")
			player.data.facing_dir = Vector2.RIGHT
			hp0 = enemy.stats.health.current
			_press(); t0 = frames; phase = 1
		1:
			if frames == t0 + 2:
				_release()
				proj = _find_proj()
				first_proj = proj
				check(proj != null, "projectile spawned beside player (not as child)")
				if proj:
					check(not proj.is_launched() and not proj.visible, "held during windup")
				check(player.data.inventory.get_count(&"throwing_dagger") == 1, "one dagger spent")
			if frames == t0 + 14:
				check(proj != null and is_instance_valid(proj) and proj.is_launched(), "launched after windup")
				# getting hit mid-flight must not cancel it
				player._on_damage_received(1.0, true)
				check(proj.is_inside_tree() and not proj.is_released(), "survives thrower's hitstun")
			if frames == t0 + 60:
				check(not proj.is_inside_tree() and proj.is_released(), "projectile back in the pool after hit")
				check(enemy.stats.health.current < hp0, "enemy damaged (%d -> %d)" % [hp0, enemy.stats.health.current])
				# throw the last one into empty space: expires at range
				enemy.global_position = Vector2(5000, -5000)
				player.data.facing_dir = Vector2.RIGHT
				player.data.hurt_timer = 0.0; player.data.is_hurt = false
				_press(); t0 = frames; phase = 2
		2:
			if frames == t0 + 2:
				_release()
				proj = _find_proj()
				check(proj != null and proj == first_proj and not proj.is_launched() and not proj.visible, "second throw reuses the pooled dagger, reset")
				check(player.data.inventory.get_count(&"throwing_dagger") == 0, "last dagger spent")
			if frames == t0 + 40:
				check(player.data.equipment.get_item(EquippableItem.Slot.WEAPON) == null, "auto-unequipped when out")
				check(player.data.current_attack == &"unarmed", "back to unarmed")
				check(is_instance_valid(proj) and proj.is_launched(), "last dagger still flying after unequip")
			if frames == t0 + 100:
				check(not proj.is_inside_tree() and proj.is_released(), "expired at max range")
				# no daggers: can't re-equip
				check(not player.player_equipment_system.try_equip(player.data, dagger), "can't equip with none")
				finish("PROJECTILE")
