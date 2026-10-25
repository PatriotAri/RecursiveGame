extends TestBase
var game: Node
var player
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	game.starting_map = &"test_level_01"
	add_child(game)
func _sfx_count(effect) -> int:
	return AudioManager._playing_counts.get(effect, 0)
func step() -> void:
	if frames != 20: return
	player = get_tree().get_first_node_in_group(&"player")
	# limit
	var ok := 0
	for i in 10:
		if AudioManager.play_sfx(GlobalSounds.hit, Vector2.ZERO): ok += 1
	check(ok == GlobalSounds.hit.max_instances, "max_instances respected (%d played)" % ok)
	# ui click via any button
	var b := Button.new(); add_child(b)
	var before := _sfx_count(GlobalSounds.ui_click)
	b.pressed.emit()
	check(_sfx_count(GlobalSounds.ui_click) == before + 1, "button press clicks")
	# player hurt
	var hurt = player.hurt_sound
	player._on_damage_received(1.0, true)
	check(_sfx_count(hurt) == 1, "player hurt sound")
	# potion
	var potion: ConsumableItem = load("res://game/items/consumables/potions/health_potion/health_potion.tres")
	player.data.inventory.add(potion, 1)
	check(player.player_consumable_system.try_use(player.data, potion), "potion used")
	check(_sfx_count(potion.use_sound) == 1, "potion sound")
	# equip
	var sword: EquippableItem = load("res://game/items/equipment/weapons/tier_1/iron_sword/iron_sword.tres")
	player.data.inventory.add(sword, 1)
	player.player_equipment_system.try_equip(player.data, sword)
	check(_sfx_count(GlobalSounds.equip) == 1, "equip sound")
	check(sword.attack.sound != null, "sword has swing sound")
	finish("SFX")
