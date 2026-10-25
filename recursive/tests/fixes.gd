extends TestBase
## v0.15 regressions: bat patrol stays in bounds; armed animation lookup.
var game: Game
var player
var bat
var phase := 0
func _ready() -> void:
	game = load("res://game/game.tscn").instantiate()
	add_child(game)
func step() -> void:
	match phase:
		0:
			if frames < 30: return
			phase = 1
			player = get_tree().get_first_node_in_group(&"player")
			# Level 1 arena corner: a bat's 320x260 patrol zone here hangs well
			# past the outer wall.
			bat = spawn_enemy(BAT, Vector2(1820, 120))
			player.global_position = Vector2(288, 352)   # far away: bat stays idle/patrolling
		1:
			if frames < 40: return
			phase = 2
			var walls: TileMapLayer = game.current_map.get_node("Walls")
			var ground: TileMapLayer = game.current_map.get_node("Ground")
			var bad := 0
			for i in 60:
				bat.movement_system.pick_patrol_target()
				var t: Vector2 = bat.movement_system.patrol_target
				if ground.get_cell_source_id(ground.local_to_map(t)) == -1: bad += 1
			check(bad == 0, "bat patrol targets all on the floor (%d off-map of 60)" % bad)
			check(not bat.uses_pathfinding() and bat.navigation.has_navigation(), "bat flies straight but sees the navmesh")
			# animation: with a prefix and no armed art, falls back to the base set
			player.data.animation_prefix = "onehand"
			player.player_animation_system.update(player.data)
			check(player.sprite.animation.begins_with("idle_"), "missing armed art falls back (%s)" % player.sprite.animation)
			# fake armed art: the prefixed name wins once it exists
			var frames_res: SpriteFrames = player.sprite.sprite_frames
			var dir := FacingHelper.facing_to_string(player.data.facing_dir)
			frames_res.add_animation("onehand_idle_" + dir)
			frames_res.add_frame("onehand_idle_" + dir, frames_res.get_frame_texture("idle_" + dir, 0))
			player.player_animation_system.update(player.data)
			check(player.sprite.animation == "onehand_idle_" + dir, "armed art used when present (%s)" % player.sprite.animation)
			frames_res.remove_animation("onehand_idle_" + dir)
			check(player.data.turn_speed > 0.0, "turn_speed renamed")
			# item database lists every item resource in the project
			var missing := []
			_scan("res://game", missing)
			check(missing.is_empty(), "every item is in ItemDatabase %s" % str(missing))
			finish("FIXES")
func _scan(dir: String, missing: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".tres"):
			var r = load(dir + "/" + f)
			if r is Item and SaveManager.ITEMS.find(r.id) == null: missing.append(r.id)
	for d in DirAccess.get_directories_at(dir):
		_scan(dir + "/" + d, missing)
