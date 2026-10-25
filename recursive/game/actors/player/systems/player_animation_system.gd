class_name PlayerAnimationSystem

extends ActorAnimator

## Drives the player's sprite layers. The body ($Sprite) is the master: it
## picks the animation, owns the timing, and is what "animation finished"
## means. Feet, Arms and Head are children of it that play the same
## animation, locked to the body's frame every time it changes — so they
## also inherit its position and the damage flash.
##
## Each layer resolves the name on its own. A layer drawn for the current
## weapon stance ("onehand_attack_S") plays that; one without it plays the
## unarmed version ("attack_S"); one with neither, or with no frames at
## all, hides. That's what lets a stance ship as arms-only art.

## Child layers, back to front. Feet draws behind the body (show_behind_parent
## in the scene); the rest draw over it in this order.
const LAYERS: Array[StringName] = [&"Feet", &"Arms", &"Head"]

var layers: Array[AnimatedSprite2D] = []

## The scene's own frames per layer, restored when equipment stops
## overriding them.
var _default_frames: Dictionary = {}
var _base_name:= ""
var _armed_name:= ""

func _init(sprite_ref: AnimatedSprite2D) -> void:
	super(sprite_ref)
	for layer_name in LAYERS:
		var layer := sprite.get_node_or_null(NodePath(String(layer_name))) as AnimatedSprite2D
		if layer == null: continue
		layers.append(layer)
		_default_frames[layer_name] = layer.sprite_frames
	# Synced on the body's own frame changes rather than once per physics
	# tick, so a layer can never be a frame behind the body it sits on.
	sprite.frame_changed.connect(_sync_layers)
	sprite.animation_changed.connect(_sync_layers)

## Gives a layer different art — a helmet replacing the head. Null puts the
## scene's own frames back.
func set_layer_frames(layer_name: StringName, frames: SpriteFrames) -> void:
	for layer in layers:
		if layer.name == layer_name:
			layer.sprite_frames = frames if frames else _default_frames.get(layer_name)
	_sync_layers()

## `attack_duration` is the swing's full length; the attack animation is
## stretched or squeezed to match it.
func update(data: PlayerData, attack_duration := 0.0) -> void:
	_base_name = _base_animation(data)
	_armed_name = data.animation_prefix + "_" + _base_name if data.animation_prefix != "" else ""
	play_state(_resolve_for(sprite.sprite_frames), data.hurt_seq,
		data.current_state == PlayerData.State.HURT,
		data.current_state == PlayerData.State.ATTACK, attack_duration)
	_sync_layers()

#Applies the current stance to the unarmed animation name, where art for it
#exists. A stance can ship partly drawn — anything missing falls back to the
#unarmed version of that same state, so a half-finished set never leaves the
#player invisible or frozen.
func _resolve_for(frames: SpriteFrames) -> String:
	if frames == null: return ""
	if _armed_name != "" and frames.has_animation(_armed_name):
		return _armed_name
	if frames.has_animation(_base_name):
		return _base_name
	return ""

## Points every layer at the body's current frame. Layers don't play on
## their own; they're posed.
func _sync_layers() -> void:
	for layer in layers:
		var anim := _resolve_for(layer.sprite_frames)
		if anim == "":
			layer.visible = false
			continue
		layer.visible = true
		if layer.animation != anim:
			layer.animation = anim
		# Clamped: a layer drawn with fewer frames than the body holds its
		# last one rather than going blank.
		layer.frame = mini(sprite.frame, layer.sprite_frames.get_frame_count(anim) - 1)

#turns state + facing into an animation name string
func _base_animation(data: PlayerData) -> String:
	#gets name of the direction youre facing
	var dir:= FacingHelper.facing_to_string(data.facing_dir)
	
	#Gets the current player state from player data, combines with 
	#direction, and outputs the proper animation name to be called.
	match data.current_state:
		PlayerData.State.DIED:
			return "died"
		PlayerData.State.HURT:
			return "hurt_" + dir
		PlayerData.State.WALK:
			if data.is_running:
				return "run_" + dir
			else:
				return "walk_" + dir
		PlayerData.State.ATTACK:
			return "attack_" + dir
		_:
			return "idle_" + dir
