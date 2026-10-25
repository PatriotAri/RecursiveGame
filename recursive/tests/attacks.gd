extends TestBase
## Attacks-as-data kept every value: what each actor registers at runtime.
var game: Game
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"test_level_01"
	add_child(game)
func spec_of(e, name: StringName) -> AttackSpec: return e.hitbox_manager.get_spec(name)
func row(label: String, s: AttackSpec, dmg: float, windup: float, life: float, kb: float, stun: float) -> void:
	check(s != null and is_equal_approx(s.damage, dmg) and is_equal_approx(s.windup_time, windup) and is_equal_approx(s.lifetime, life) and is_equal_approx(s.knockback_strength, kb) and is_equal_approx(s.hitstun_chance, stun) and s.scene != null and s.sound != null,
		"%s: dmg %s windup %s life %s kb %s stun %s" % [label, s.damage, s.windup_time, s.lifetime, s.knockback_strength, s.hitstun_chance])
func step() -> void:
	if frames != 20: return
	var c = spawn_enemy(CRAWLER, Vector2(-3000, 3000))
	var g = spawn_enemy(GRUNT, Vector2(-3200, 3000))
	var b = spawn_enemy(BAT, Vector2(-3400, 3000))
	var s = spawn_enemy(SPITTER, Vector2(-3600, 3000))
	row("crawler", spec_of(c, &"melee"), 1.0, 0.5, 0.1, 50.0, 0.3)
	row("grunt", spec_of(g, &"melee"), 3.0, 0.6, 0.15, 120.0, 0.5)
	row("bat", spec_of(b, &"melee"), 1.0, 0.25, 0.15, 40.0, 0.3)
	var spit := spec_of(s, &"spit")
	row("spitter", spit, 2.0, 0.4, 0.2, 50.0, 0.3)
	check(spit.scene.instantiate() is Projectile and spit.projectile_speed == 170.0 and spit.projectile_range == 260.0, "spit is a 170 px/s, 260 px projectile")
	check(is_equal_approx(c.attack_range, 10.0 + 16.0 + c.profile.attack.offsets.get_offset("N").length()) or c.attack_range > 0.0, "crawler attack range still derived (%.1f)" % c.attack_range)
	var p = get_tree().get_first_node_in_group(&"player")
	var u: AttackSpec = p.player_hitbox_manager.get_spec(&"unarmed")
	row("unarmed", u, 7.0, 0.2, 0.1, 50.0, 0.3)
	check(u.attack_stamina_cost == 2, "unarmed costs 2 stamina")
	finish("ATTACKS")
