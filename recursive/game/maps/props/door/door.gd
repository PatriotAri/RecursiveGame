@tool
class_name Door

extends StaticBody2D

## A blocking section of wall that can open. Closed, it collides like a wall
## and is cut out of the navigation map; open, it's gone. Sized in the
## inspector, so one scene covers doorways and gates of any shape.

## Emitted after opening or closing, so the level can rebuild navigation.
signal changed

@export var size := Vector2(64, 128):
	set(value):
		size = value
		_apply_size()
@export var starts_open := false
@export var open_sound: SoundEffect
@export var close_sound: SoundEffect

var is_open := false

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_apply_size()
	if Engine.is_editor_hint(): return
	_set_open(starts_open, false)

func open() -> void:
	_set_open(true, true)

func close() -> void:
	_set_open(false, true)

func _set_open(value: bool, announce: bool) -> void:
	if value == is_open and announce: return
	is_open = value
	# Deferred: doors open from inside physics callbacks (an enemy dying).
	_shape.set_deferred("disabled", is_open)
	_sprite.visible = not is_open
	if is_open:
		remove_from_group(&"navigation_obstacles")
	else:
		add_to_group(&"navigation_obstacles")
	if announce:
		Sfx.play(open_sound if is_open else close_sound, global_position)
		changed.emit()

func _apply_size() -> void:
	if not is_node_ready(): return
	(_shape.shape as RectangleShape2D).size = size
	_sprite.region_rect = Rect2(Vector2.ZERO, size)
