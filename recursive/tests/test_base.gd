class_name TestBase
extends Node
## Test harness. Each test is a scene whose root extends this; run them
## with tests/run_tests.sh.
var frames := 0
func _init() -> void:
	# Keep driving the test while a menu has the game paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Autoloads are already up when the test scene is built. Tests save,
	# autosave and delete saves; none of it may touch the player's own.
	SaveManager.save_path = "user://test_save_slot.json"
	AudioManager.settings_path = "user://test_settings.cfg"
var failed := false
func check(cond: bool, what: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + what)
	if not cond: failed = true
func finish(name: String) -> void:
	print("%s %s" % [name, "FAIL" if failed else "PASS"])
	get_tree().quit(1 if failed else 0)
func _physics_process(_d: float) -> void:
	frames += 1
	step()
func step() -> void:
	pass

const CRAWLER := "res://game/actors/enemies/types/fodder/crawler/core/crawler.tscn"
const SPITTER := "res://game/actors/enemies/types/ranged/spitter/core/spitter.tscn"
const BAT := "res://game/actors/enemies/types/flyer/bat/core/bat.tscn"
const GRUNT := "res://game/actors/enemies/types/normal/grunt/core/grunt.tscn"

## Spawns an enemy next to the player's parent (the map's entity root).
func spawn_enemy(path: String, pos: Vector2) -> Node:
	var p := get_tree().get_first_node_in_group(&"player")
	var e: Node2D = load(path).instantiate()
	p.get_parent().add_child(e)
	e.global_position = pos
	return e
