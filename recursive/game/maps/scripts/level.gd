class_name Level

extends Node2D

## Runs a level's rounds. Every round fights through the unlocked areas in
## order: clearing one opens the door to the next and spawns its enemies, and
## clearing the newest one ends the round and unlocks one more area for next
## time. During a round the return gates and the airship ramp are shut;
## between rounds they're open. Once the last area has been cleared, the exit
## door to the next level opens.

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
	_set_between_rounds()

func start_round() -> void:
	if state == State.IN_ROUND or areas.is_empty(): return
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

func _set_between_rounds() -> void:
	state = State.BETWEEN_ROUNDS
	start_stand.enabled = true
	if ramp: ramp.enabled = true
	# Gates only open from areas already fought in, so a locked area can't be
	# reached early through the loop-back path.
	for i in areas.size():
		var gate:= areas[i].return_gate
		if gate == null: continue
		if i < unlocked_areas - 1 or (round_number > 0 and i <= _current_area):
			gate.open()
		else:
			gate.close()

func _all_doors() -> Array[Door]:
	var doors: Array[Door] = []
	for area in areas:
		if area.entry_door: doors.append(area.entry_door)
		if area.return_gate: doors.append(area.return_gate)
	if exit_door: doors.append(exit_door)
	return doors
