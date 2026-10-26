class_name Level

extends Node2D

## Runs a level's rounds. Every round fights through the unlocked areas in
## order: clearing one opens the door to the next and spawns its enemies, and
## clearing the newest one ends the round and unlocks one more area for next
## time. During a round the return gates and the airship ramp are shut;
## between rounds they're open. Once the last area has been cleared, the exit
## door to the next level opens.

## Emitted when a round is about to start, while the level is still between
## rounds: the last safe moment before the fighting, so the game saves here.
signal round_starting(round_number: int)
signal round_started(round_number: int)
signal round_cleared(round_number: int)
signal level_completed
## The player used the airship ramp. The map runner handles the trip.
signal airship_requested
## The player used the exit to the next level.
signal exit_requested

enum State {BETWEEN_ROUNDS, IN_ROUND}

## In the order they're fought.
@export var areas: Array[LevelArea] = []
@export var start_stand: Interactable
@export var ramp: Interactable
## Leave empty on a map's last level.
@export var exit_door: Door
@export var exit: Interactable
@export var player_spawn: Marker2D
## Where the player stands after coming back down from the airship.
@export var ramp_arrival: Marker2D
## Players, enemies and pickups go here, so they depth-sort together.
@export var actors: Node2D
@export var navigation: LevelNavigation
@export var round_start_sound: SoundEffect
@export var round_clear_sound: SoundEffect

var state:= State.BETWEEN_ROUNDS
var round_number:= 0
var unlocked_areas:= 1
var completed:= false
var _current_area:= 0
## The pickups placed in the level's scene, as instance id -> path. A loaded
## level leaves out the ones already picked up, so they can't be collected
## twice. Ids rather than paths tell them apart from drops: a drop can take a
## freed pickup's name, and so its path, but never its id.
var _placed_pickups := {}

func _ready() -> void:
	start_stand.interacted.connect(func(_player: Node) -> void: start_round())
	if ramp:
		ramp.interacted.connect(func(_player: Node) -> void: airship_requested.emit())
	if exit:
		exit.interacted.connect(func(_player: Node) -> void: exit_requested.emit())
		exit.enabled = false
	for door in _all_doors():
		door.changed.connect(navigation.rebake)
	for area in areas:
		area.cleared.connect(_on_area_cleared.bind(area))
	# Every pickup here before play starts was placed; anything later is a
	# drop.
	for pickup in _pickups():
		_placed_pickups[pickup.get_instance_id()] = get_path_to(pickup)
	_set_between_rounds()

func start_round() -> void:
	if state == State.IN_ROUND or areas.is_empty(): return
	round_starting.emit(round_number + 1)
	state = State.IN_ROUND
	round_number += 1
	_current_area = 0
	for area in areas:
		if area.entry_door: area.entry_door.close()
		if area.return_gate: area.return_gate.close()
	start_stand.enabled = false
	if ramp: ramp.enabled = false
	Sfx.play(round_start_sound)
	areas[0].spawn(_visit(0))
	round_started.emit(round_number)

## How many times area `index` has been fought before this round. Area 1 is
## new on round 1, area 2 on round 2, and so on.
func _visit(index: int) -> int:
	return round_number - 1 - index

func _on_area_cleared(area: LevelArea) -> void:
	if state != State.IN_ROUND: return
	if areas.find(area) != _current_area: return
	if _current_area + 1 < unlocked_areas:
		_current_area += 1
		var next:= areas[_current_area]
		if next.entry_door: next.entry_door.open()
		next.spawn(_visit(_current_area))
	else:
		_finish_round()

func _finish_round() -> void:
	if unlocked_areas < areas.size():
		unlocked_areas += 1
	elif not completed:
		completed = true
		if exit_door: exit_door.open()
		if exit: exit.enabled = true
		level_completed.emit()
	Sfx.play(round_clear_sound)
	var cleared_round:= round_number
	_set_between_rounds()
	round_cleared.emit(cleared_round)

## Everything needed to put the level back as it is now. Saving only happens
## between rounds, so there are no enemies to record.
func get_save_data() -> Dictionary:
	var taken: Array[String] = []
	for id in _placed_pickups:
		var pickup:= instance_from_id(id) as Node
		if pickup == null or pickup.is_queued_for_deletion():
			taken.append(String(_placed_pickups[id]))
	var drops: Array[Dictionary] = []
	for pickup in _pickups():
		if _placed_pickups.has(pickup.get_instance_id()) or pickup.is_queued_for_deletion(): continue
		if pickup.item == null or pickup.scene_file_path.is_empty(): continue
		drops.append({
			"scene": pickup.scene_file_path,
			"item": String(pickup.item.id),
			"amount": pickup.amount,
			"parent": String(get_path_to(pickup.get_parent())),
			# Local, not global: on the airship this level is out of the tree,
			# where global positions can't be read.
			"position": [pickup.position.x, pickup.position.y],
		})
	return {
		"round_number": round_number,
		"unlocked_areas": unlocked_areas,
		"last_area": _current_area,
		"completed": completed,
		"taken_pickups": taken,
		"drops": drops,
	}

## Puts the level back the way get_save_data() found it. Call once, after the
## level is in the tree. Doors move quietly; the navigation map rebakes off
## their changed signals as usual.
func load_save_data(saved: Dictionary) -> void:
	if areas.is_empty(): return
	round_number = maxi(int(saved.get("round_number", 0)), 0)
	unlocked_areas = clampi(int(saved.get("unlocked_areas", 1)), 1, areas.size())
	_current_area = clampi(int(saved.get("last_area", 0)), 0, unlocked_areas - 1)
	completed = bool(saved.get("completed", false))
	for path in saved.get("taken_pickups", []):
		var pickup:= get_node_or_null(NodePath(String(path)))
		if pickup is ItemPickup:
			pickup.free()
	for drop in saved.get("drops", []):
		_restore_drop(drop)
	# Between rounds, the doors into the areas fought last round stay open.
	for i in range(1, areas.size()):
		var door:= areas[i].entry_door
		if door and round_number > 0 and i <= _current_area:
			door.open(true)
	if completed:
		if exit_door: exit_door.open(true)
		if exit: exit.enabled = true
	_set_between_rounds(true)

## Puts a saved drop back where it lay. Skips one whose scene or item is no
## longer in the game.
func _restore_drop(drop: Dictionary) -> void:
	var scene_path:= String(drop["scene"])
	var scene: PackedScene = null
	# Only scenes from the game itself: a save file is player-editable.
	if scene_path.begins_with("res://") and ResourceLoader.exists(scene_path):
		scene = load(scene_path) as PackedScene
	var item:= ContentRegistry.get_item(StringName(drop["item"]))
	if scene == null or item == null:
		push_warning("%s: skipped a saved drop (%s, %s)." % [name, scene_path, drop["item"]])
		return
	var node:= scene.instantiate()
	var pickup:= node as ItemPickup
	if pickup == null:
		node.free()
		push_warning("%s: saved drop scene %s isn't a pickup." % [name, scene_path])
		return
	pickup.item = item
	pickup.amount = maxi(int(drop["amount"]), 1)
	pickup.position = Vector2(drop["position"][0], drop["position"][1])
	# Back under the node it lay in, as long as that's inside this level.
	var parent:= get_node_or_null(NodePath(String(drop["parent"])))
	if parent == null or not is_ancestor_of(parent):
		parent = actors
	parent.add_child(pickup)

func _set_between_rounds(quiet:= false) -> void:
	state = State.BETWEEN_ROUNDS
	start_stand.enabled = true
	if ramp: ramp.enabled = true
	# Gates only open from areas already fought in, so a locked area can't be
	# reached early through the loop-back path.
	for i in areas.size():
		var gate:= areas[i].return_gate
		if gate == null: continue
		if i < unlocked_areas - 1 or (round_number > 0 and i <= _current_area):
			gate.open(quiet)
		else:
			gate.close(quiet)

func _pickups() -> Array[ItemPickup]:
	var found: Array[ItemPickup] = []
	for node in find_children("*", "", true, false):
		if node is ItemPickup:
			found.append(node)
	return found

func _all_doors() -> Array[Door]:
	var doors: Array[Door] = []
	for area in areas:
		if area.entry_door: doors.append(area.entry_door)
		if area.return_gate: doors.append(area.return_gate)
	if exit_door: doors.append(exit_door)
	return doors
