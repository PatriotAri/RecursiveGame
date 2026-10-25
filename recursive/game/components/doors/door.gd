class_name Door

extends StaticBody2D

## A door the player opens and closes with the interact key. Locks itself
## while a round is being fought, if the map has a RoundManager. With a
## target_map set it's a passage instead: interacting loads that map.

@export var starts_open:= false
@export var locked:= false
@export var lock_during_rounds:= true
@export_group("Passage")
## Map id from the MapRegistry. Empty = an ordinary door.
@export var target_map:= &""
## Spawn point name in the target map. Empty = that map's default.
@export var target_spawn:= &""
@export_group("Look")
@export var closed_texture: Texture2D
@export var open_texture: Texture2D
@export var toggle_sound: SoundEffect = preload("res://game/audio/sfx/door.tres")
@export var denied_sound: SoundEffect = preload("res://game/audio/sfx/denied.tres")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var interactable: Interactable = $Interactable

var is_open:= false
var _round_locked:= false

func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	_set_open(starts_open, false)
	_connect_rounds.call_deferred()

func is_passage() -> bool:
	return target_map != &""

func is_locked() -> bool:
	return locked or _round_locked

func open() -> void:
	if not is_open: _set_open(true, true)

func close() -> void:
	if is_open: _set_open(false, true)

func set_locked(value: bool) -> void:
	locked = value
	_update_prompt()

func _on_interacted(_player: Node) -> void:
	if is_locked():
		AudioManager.play_sfx(denied_sound, global_position)
		return
	AudioManager.play_sfx(toggle_sound, global_position)
	if is_passage():
		var game := get_tree().get_first_node_in_group(&"game")
		if game:
			game.change_map(target_map, target_spawn)
		else:
			push_warning("%s: no Game to load '%s' — running the map on its own?" % [name, target_map])
		return
	_set_open(not is_open, true)

func _set_open(value: bool, rebake: bool) -> void:
	is_open = value
	# Deferred: can be reached from a physics callback, where shapes can't
	# be switched directly.
	collision.set_deferred("disabled", value)
	if value:
		remove_from_group(&"navigation_obstacles")
	else:
		add_to_group(&"navigation_obstacles")
	var texture := open_texture if value else closed_texture
	if texture: sprite.texture = texture
	_update_prompt()
	if rebake:
		_rebake_navigation.call_deferred()

## An open door is a gap in the navmesh, a closed one a wall. Small maps
## rebake in well under a frame, so it's simply redone.
func _rebake_navigation() -> void:
	for nav in get_tree().get_nodes_in_group(&"level_navigation"):
		if nav.owner and nav.owner.is_ancestor_of(self):
			nav.bake()

func _connect_rounds() -> void:
	if not lock_during_rounds: return
	var map := _find_map()
	var rounds: RoundManager = map.get_round_manager() if map else null
	if rounds == null: return
	rounds.round_started.connect(_on_round_started)
	rounds.round_completed.connect(_on_round_completed)

func _on_round_started(_round: int) -> void:
	_round_locked = true
	if is_open and not is_passage():
		_set_open(false, true)
	_update_prompt()

func _on_round_completed(_round: int) -> void:
	_round_locked = false
	_update_prompt()

func _find_map() -> Map:
	var node: Node = self
	while node and not (node is Map):
		node = node.get_parent()
	return node as Map

func _update_prompt() -> void:
	if interactable == null: return
	if _round_locked:
		interactable.set_prompt("Locked until the round ends")
	elif locked:
		interactable.set_prompt("Locked")
	elif is_passage():
		interactable.set_prompt("Enter")
	else:
		interactable.set_prompt("Close" if is_open else "Open")
