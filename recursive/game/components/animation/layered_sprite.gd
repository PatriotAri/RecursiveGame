class_name LayeredSprite

extends Node2D

## Plays one animation across a stack of AnimatedSprite2D children — body
## parts, and the armour drawn over them — and keeps every layer on the same
## frame. The layers are the AnimatedSprite2D children, drawn in tree order.
## Anything else parented here, like a held weapon, is left alone.
##
## Only the lead layer actually plays. Every other layer is set to the lead's
## frame each tick, so they can't drift apart however their frame rates or
## start times were authored.

## Emitted when the lead layer finishes a non-looping animation.
signal animation_finished

## The layer whose clock every other layer follows. It should have every
## animation the stack is asked to play.
@export var lead_layer: AnimatedSprite2D
## Where the weapon hand is on each frame. Optional.
@export var hand_points: HandPointData
## Animation suffixes drawn by flipping another direction's art. A layer only
## mirrors when it has no art of its own for the requested animation, so one
## hand-drawn west-facing set overrides the flip for that layer alone.
@export var mirrored_suffixes: Dictionary[String, String] = {
	"_W": "_E",
	"_SW": "_SE",
	"_NW": "_NE",
}

var _layers: Array[AnimatedSprite2D] = []
var _current: StringName = &""
var _fallback: StringName = &""

func _ready() -> void:
	# Children process before this node at the same priority only by luck of
	# tree order; a higher priority guarantees the lead has advanced its frame
	# before the others copy it.
	process_priority = 1
	for child in get_children():
		if child is AnimatedSprite2D:
			_layers.append(child)
	if lead_layer == null:
		push_error("%s: no lead layer assigned." % name)
		return
	lead_layer.animation_finished.connect(animation_finished.emit)
	# Start on whatever the lead was saved showing, so the stack is consistent
	# from the first drawn frame — before anything has called play(). Empty
	# armour layers hide here instead of waiting for the first play().
	_current = lead_layer.animation
	for layer in _layers:
		if layer != lead_layer:
			_apply_layer(layer)

func _process(_delta: float) -> void:
	_sync_frames()

## True if the lead layer can show `animation`, drawn or mirrored.
func has_animation(animation: StringName) -> bool:
	var frames := lead_layer.sprite_frames
	if frames == null: return false
	if frames.has_animation(animation): return true
	var source := _mirror_source(animation)
	return source != &"" and frames.has_animation(source)

## Plays `animation` on every layer that has it. A layer without it plays
## `fallback` instead, and a layer with neither hides — so a helmet drawn for
## the base set still shows during a weapon's own animations, and a missing
## piece of art never leaves a stale frame on screen.
func play(animation: StringName, fallback: StringName = &"", restart := false) -> void:
	if animation == _current and fallback == _fallback and not restart:
		return
	_current = animation
	_fallback = fallback
	var pick := _pick(lead_layer)
	if pick[0] == &"":
		push_warning("%s: lead layer has neither '%s' nor '%s'." % [name, animation, fallback])
		return
	lead_layer.flip_h = pick[1]
	lead_layer.play(pick[0])
	if restart:
		lead_layer.set_frame_and_progress(0, 0.0)
	for layer in _layers:
		if layer != lead_layer:
			_apply_layer(layer)

## Holds the current animation on the frame matching `progress` (0 to 1)
## instead of letting it run on its frame rate. For animations that have to
## line up with a gameplay timer, like an attack and its hitbox.
func set_progress(progress: float) -> void:
	if lead_layer.sprite_frames == null: return
	if lead_layer.is_playing():
		lead_layer.pause()
	var count := lead_layer.sprite_frames.get_frame_count(lead_layer.animation)
	lead_layer.frame = clampi(floori(progress * count), 0, count - 1)
	_sync_frames()

## Swaps the art on one layer — equipping and unequipping armour. Null clears
## the layer.
func set_layer_frames(layer_name: StringName, frames: SpriteFrames) -> void:
	var layer := _get_layer(layer_name)
	if layer == null: return
	layer.sprite_frames = frames
	if layer == lead_layer:
		push_warning("%s: replacing the lead layer's frames." % name)
		return
	_apply_layer(layer)

## Draws one layer through `material`, e.g. armour recoloured to what it's
## made of. Null draws it as it is.
func set_layer_material(layer_name: StringName, layer_material: Material) -> void:
	var layer := _get_layer(layer_name)
	if layer == null: return
	layer.material = layer_material

## Moves a layer in front of or behind its siblings without reordering the
## tree. 0 is the layer's place in the stack.
func set_layer_z(layer_name: StringName, z: int) -> void:
	var layer := _get_layer(layer_name)
	if layer == null: return
	layer.z_index = z

func get_layer_z(layer_name: StringName) -> int:
	var layer := _get_layer(layer_name)
	return layer.z_index if layer else 0

## True while the lead layer is showing flipped art.
func is_mirrored() -> bool:
	return lead_layer.flip_h

## The weapon hand on the current frame, in this node's space. Points are
## authored for the art as drawn, so a flipped frame flips its point too.
func hand_point() -> Vector2:
	if hand_points == null: return Vector2.ZERO
	var point := hand_points.get_point(lead_layer.animation, lead_layer.frame)
	if lead_layer.flip_h:
		point.x = -point.x
	return point

func _get_layer(layer_name: StringName) -> AnimatedSprite2D:
	var layer := get_node_or_null(NodePath(layer_name)) as AnimatedSprite2D
	if layer == null:
		push_warning("%s: no layer named '%s'." % [name, layer_name])
	return layer

## [animation to play, whether to flip it]. Own art beats mirrored art, and
## the requested animation beats the fallback.
func _pick(layer: AnimatedSprite2D) -> Array:
	var frames := layer.sprite_frames
	if frames == null: return [&"", false]
	for animation in [_current, _fallback]:
		if animation == &"": continue
		if frames.has_animation(animation):
			return [animation, false]
		var source := _mirror_source(animation)
		if source != &"" and frames.has_animation(source):
			return [source, true]
	return [&"", false]

func _mirror_source(animation: StringName) -> StringName:
	var text := String(animation)
	for suffix in mirrored_suffixes:
		if text.ends_with(suffix):
			return StringName(text.trim_suffix(suffix) + mirrored_suffixes[suffix])
	return &""

func _apply_layer(layer: AnimatedSprite2D) -> void:
	var pick := _pick(layer)
	layer.visible = pick[0] != &""
	if pick[0] == &"": return
	layer.flip_h = pick[1]
	if layer.animation != pick[0]:
		layer.animation = pick[0]
	_sync_layer(layer)

func _sync_frames() -> void:
	for layer in _layers:
		if layer != lead_layer and layer.visible:
			_sync_layer(layer)

func _sync_layer(layer: AnimatedSprite2D) -> void:
	if layer.sprite_frames == null or not layer.sprite_frames.has_animation(layer.animation):
		return
	var count := layer.sprite_frames.get_frame_count(layer.animation)
	layer.frame = mini(lead_layer.frame, count - 1)
