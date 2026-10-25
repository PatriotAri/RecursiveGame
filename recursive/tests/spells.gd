extends TestBase
var game: Node
var player
var e1
var e2
var staff
var phase := 0
var t0 := 0
var hp1 := 0
var hp2 := 0
var mana0 := 0
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"test_level_01"
	add_child(game)
func tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)
func step() -> void:
	match phase:
		0:
			if frames < 20: return
			phase = 1
			player = get_tree().get_first_node_in_group(&"player")
			spawn_enemy(CRAWLER, Vector2(-3000, 3000))
			spawn_enemy(CRAWLER, Vector2(-3100, 3000))
			var enemies := get_tree().get_nodes_in_group(&"enemy")
			e1 = enemies[0]; e2 = enemies[1]
			for e in [e1, e2]: e.set_physics_process(false)
			e1.global_position = player.global_position + Vector2(220, 0)
			e2.global_position = player.global_position + Vector2(240, 20)
			# no staff: cast does nothing
			player.data.facing_dir = Vector2.RIGHT
			mana0 = player.stats.mana.current
			tap("player_cast"); t0 = frames
		1:
			if frames == t0 + 10:
				check(player.stats.mana.current == mana0, "no staff -> no cast")
				check(not player.data.is_attacking, "no attack started")
				staff = load("res://game/items/equipment/weapons/tier_1/apprentice_staff/apprentice_staff.tres")
				check(staff is EnchantedEquippableItem, "staff is EnchantedEquippableItem")
				player.data.inventory.add(staff, 1)
				player.player_equipment_system.try_equip(player.data, staff)
				check(player.stats.mana.maximum == 20, "staff +10 max mana (%d)" % player.stats.mana.maximum)
				check(player.data.current_spell_attack == &"spell_fireball", "fireball selected")
				hp1 = e1.stats.health.current; hp2 = e2.stats.health.current
				mana0 = player.stats.mana.current
				tap("player_cast"); t0 = frames; phase = 2
		2:
			if frames == t0 + 4:
				check(player.stats.mana.current == mana0 - 4, "cast spent 4 mana (%d -> %d)" % [mana0, player.stats.mana.current])
				check(player.data.active_attack == &"spell_fireball", "active attack is the spell")
				var fb = null
				for n in player.get_parent().get_children():
					if n is Fireball: fb = n
				check(fb != null, "fireball spawned")
			if frames == t0 + 30:
				# still on cooldown: a second cast is refused
				tap("player_cast")
			if frames == t0 + 36:
				check(player.stats.mana.current >= mana0 - 4, "cooldown blocks recast")
			if frames == t0 + 90:
				check(e1.stats.health.current < hp1, "direct target hurt (%d -> %d)" % [hp1, e1.stats.health.current])
				check(e2.stats.health.current < hp2, "splash hit neighbour (%d -> %d)" % [hp2, e2.stats.health.current])
				# LMB still swings the staff
				tap("player_attack"); t0 = frames; phase = 3
		3:
			if frames == t0 + 4:
				check(player.data.active_attack == &"apprentice_staff", "LMB uses staff melee")
				# unequip -> spells gone
				player.data.is_attacking = false
				player.player_equipment_system.try_unequip(player.data, EquippableItem.Slot.WEAPON)
				check(player.player_spell_system.selected_spell() == null, "no spells after unequip")
				check(player.data.current_spell_attack == &"", "spell attack cleared")
				var hud_slot = game.get_node("Hud").spell_slot
				check(not hud_slot.visible, "hud spell slot hidden")
				finish("SPELLS")
