extends TestBase
var game: Game
var player
var anim: PlayerAnimationSystem
var phase := 0
var t0 := 0
var max_desync := 0
var crawler
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	add_child(game)
## Frames for a layer, one tinted frame per animation, `count` frames each.
func fake_frames(names: Array, count: int) -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation(&"default")
	var tex: Texture2D = player.sprite.sprite_frames.get_frame_texture("idle_S", 0)
	for n in names:
		f.add_animation(n)
		f.set_animation_speed(n, 8.0)
		for i in count: f.add_frame(n, tex)
	return f
func dirs() -> Array: return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
func step() -> void:
	match phase:
		0:
			if frames < 30: return
			phase = 1
			player = get_tree().get_first_node_in_group(&"player")
			anim = player.player_animation_system
			check(anim.layers.size() == 3, "three layers found under the body")
			var all_hidden := true
			for l in anim.layers: all_hidden = all_hidden and not l.visible
			check(all_hidden, "layers with no art stay hidden (game looks unchanged)")
			# head art for idle/walk only; arms art for the one-handed attack only
			var head_names := []
			for d in dirs(): head_names += ["idle_" + d, "walk_" + d, "run_" + d, "attack_" + d]
			anim.layers[2].sprite_frames = fake_frames(head_names, 4)
			anim._default_frames[&"Head"] = anim.layers[2].sprite_frames
			var arm_names := []
			for d in dirs(): arm_names.append("onehand_attack_" + d)
			anim.layers[1].sprite_frames = fake_frames(arm_names, 2)
			anim._default_frames[&"Arms"] = anim.layers[1].sprite_frames
			player.data.facing_dir = Vector2.DOWN
			t0 = frames
		1:
			var head: AnimatedSprite2D = anim.layers[2]
			if head.visible:
				max_desync = maxi(max_desync, absi(head.frame - mini(player.sprite.frame, 3)))
			if frames == t0 + 40:
				check(head.visible and head.animation == "idle_S", "head plays the body's animation (%s)" % head.animation)
				check(max_desync == 0, "head locked to the body's frame")
				check(not anim.layers[1].visible, "arms hidden: no unarmed arm art")
				# equip the sword (onehand prefix) and swing
				var sword: EquippableItem = SaveManager.ITEMS.find(&"iron_sword")
				player.data.inventory.add(sword, 1)
				player.player_equipment_system.try_equip(player.data, sword)
				player.data.facing_dir = Vector2.DOWN
				Input.action_press("player_attack")
				t0 = frames; phase = 2
		2:
			if frames == t0 + 2: Input.action_release("player_attack")
			if frames == t0 + 4:
				check(player.data.is_attacking, "swinging")
				check(player.sprite.animation == "attack_S", "body has no onehand art -> base attack (%s)" % player.sprite.animation)
				check(anim.layers[1].visible and anim.layers[1].animation == "onehand_attack_S", "arms play the one-handed attack (%s)" % anim.layers[1].animation)
				check(anim.layers[2].animation == "attack_S", "head plays the base attack")
				var expected := AnimationTiming.speed_to_fit(player.sprite.sprite_frames, &"attack_S", player.player_attack_system.attack_duration)
				var natural := AnimationTiming.natural_length(player.sprite.sprite_frames, &"attack_S")
				check(is_equal_approx(player.sprite.speed_scale, expected), "attack speed fitted (%.2fx: %.2fs of frames over a %.2fs swing)" % [player.sprite.speed_scale, natural, player.player_attack_system.attack_duration])
			if frames == t0 + 60:
				check(player.sprite.speed_scale == 1.0, "speed back to normal after the swing")
				# helmet with its own head art overrides the head layer
				var helm := (SaveManager.ITEMS.find(&"iron_helm") as EquippableItem).duplicate()
				helm.layer = &"Head"
				helm.layer_frames = fake_frames(["idle_S"], 1)
				player.data.inventory.add(helm, 1)
				player.player_equipment_system.try_equip(player.data, helm)
				check(anim.layers[2].sprite_frames == helm.layer_frames, "worn helmet replaces the head art")
				player.player_equipment_system.try_unequip(player.data, EquippableItem.Slot.HEAD)
				check(anim.layers[2].sprite_frames == anim._default_frames[&"Head"], "taking it off restores the head")
				# enemies fit their attack animation too
				crawler = spawn_enemy(CRAWLER, player.global_position + Vector2(22, 0))
				t0 = frames; phase = 3
		3:
			if crawler.data.current_state == EnemyData.State.ATTACK and not has_meta("seen"):
				set_meta("seen", true)
				var dur: float = crawler.attack_system.attack_duration
				var want := AnimationTiming.speed_to_fit(crawler.sprite.sprite_frames, crawler.sprite.animation, dur)
				check(is_equal_approx(crawler.sprite.speed_scale, want), "crawler attack fitted to its %.2fs swing (%.2fx)" % [dur, crawler.sprite.speed_scale])
			if frames == t0 + 240:
				check(has_meta("seen"), "crawler attacked")
				finish("LAYERS")
