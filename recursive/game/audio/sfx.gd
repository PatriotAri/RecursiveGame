extends Node

## Plays every sound effect from a fixed pool of players, so nothing creates
## or frees audio nodes mid-game. World sounds come from a position and fade
## with distance from the camera; UI sounds play flat. Autoloaded as Sfx.
## The shared sounds below are assigned in sfx.tscn.

const WORLD_VOICES := 24
const FLAT_VOICES := 8
## World sounds fall to silence at this distance from the camera.
const WORLD_MAX_DISTANCE := 900.0

@export_group("UI")
## Every button and slider gets these automatically — see _on_node_added().
@export var ui_click: SoundEffect
@export var ui_hover: SoundEffect
@export var menu_open: SoundEffect
@export var menu_close: SoundEffect
## An action that can't happen, like drinking a potion at full health.
@export var refused: SoundEffect

@export_group("Items")
## For items without a pickup sound of their own.
@export var pickup: SoundEffect
@export var item_drop: SoundEffect
## For equipment without an equip sound of its own.
@export var equip: SoundEffect
@export var unequip: SoundEffect

@export_group("Game")
@export var death_sting: SoundEffect

var _world: Array[AudioStreamPlayer2D] = []
var _flat: Array[AudioStreamPlayer] = []
var _effect_of: Dictionary = {}  # player -> the SoundEffect it last started

func _ready() -> void:
	# UI sounds have to play while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in WORLD_VOICES:
		var player := AudioStreamPlayer2D.new()
		player.max_distance = WORLD_MAX_DISTANCE
		add_child(player)
		_world.append(player)
	for i in FLAT_VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_flat.append(player)
	get_tree().node_added.connect(_on_node_added)

## Plays `effect` from world position `at`, or flat when `at` is left out.
## Null effects are ignored, so callers don't need to check for unassigned
## sounds.
func play(effect: SoundEffect, at := Vector2.INF) -> void:
	if effect == null: return
	var stream := effect.pick_stream()
	if stream == null: return
	if _voices_in_use(effect) >= effect.max_voices: return
	var positional := at.is_finite()
	var player = _free_player(_world if positional else _flat)
	# Every voice busy: drop this one rather than cut off something already
	# playing.
	if player == null: return
	player.stream = stream
	player.volume_db = effect.volume_db
	player.pitch_scale = effect.pick_pitch()
	player.bus = effect.bus
	if positional:
		player.global_position = at
	_effect_of[player] = effect
	player.play()

func _free_player(pool: Array) -> Node:
	for player in pool:
		if not player.playing:
			return player
	return null

func _voices_in_use(effect: SoundEffect) -> int:
	var count := 0
	for player in _effect_of:
		if _effect_of[player] == effect and player.playing:
			count += 1
	return count

## Hooks every button and slider as it enters the tree, so menus get click
## and hover sounds without each one wiring its own.
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play.bind(ui_click))
		node.mouse_entered.connect(_on_control_hovered.bind(node))
		node.focus_entered.connect(_on_control_hovered.bind(node))
	elif node is Slider:
		node.drag_ended.connect(func(_value_changed: bool) -> void: play(ui_click))

func _on_control_hovered(control: Control) -> void:
	if control is BaseButton and control.disabled: return
	play(ui_hover)
