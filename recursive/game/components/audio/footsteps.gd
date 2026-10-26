class_name Footsteps

extends Node2D

## Plays a step every `stride` pixels its parent travels. Drop one into any
## walking actor at its feet and give it a sound; faster movement means
## quicker steps with no extra setup.

@export var sound: SoundEffect
@export var stride:= 28.0
## Below this speed (px/s) the actor counts as standing still, so drifting to
## a stop doesn't patter.
@export var min_speed:= 20.0

var _travelled:= 0.0
var _last_position:= Vector2.ZERO

func _ready() -> void:
	_last_position = global_position

func _physics_process(delta: float) -> void:
	var position_now:= global_position
	var moved:= position_now.distance_to(_last_position)
	_last_position = position_now
	# A jump of several strides in one frame is a teleport — being placed by
	# a spawner, say — not walking.
	if moved > stride * 4.0:
		return
	if sound == null or moved < min_speed * delta:
		# The first step after setting off comes half a stride in, not a
		# whole one, so starting to walk is heard straight away.
		_travelled = stride * 0.5
		return
	_travelled += moved
	if _travelled >= stride:
		_travelled -= stride
		Sfx.play(sound, position_now)
