class_name PlayerWeaponVisualSystem

## Facings where the weapon belongs behind the body rather than in front.
const BEHIND := ["up", "up_left", "up_right"]

var sprite: Sprite2D

var _hold: HitboxOffsetData
var _rest_offset:= 0.0
var _swing_arc:= 0.0

func _init(sprite_ref: Sprite2D) -> void:
	sprite = sprite_ref
	# Start from a known state rather than trusting whatever the scene saved.
	set_weapon(null)

## Called by equipment on every weapon-slot change, unequipping included.
func set_weapon(item: EquippableItem) -> void:
	# An item with no texture or no offsets can't be drawn, so it's treated
	# the same as no item. Armour reaches this too and correctly shows nothing.
	if item == null or item.held_texture == null or item.hold_offsets == null:
		_hold = null
		_rest_offset = 0.0
		_swing_arc = 0.0
		sprite.offset = Vector2.ZERO
		sprite.texture = null
		sprite.visible = false
		return
	_hold = item.hold_offsets
	_rest_offset = deg_to_rad(item.rest_angle_degrees)
	_swing_arc = deg_to_rad(item.swing_arc_degrees)
	sprite.offset = item.grip_offset
	sprite.texture = item.held_texture
	sprite.visible = true

func update(data: PlayerData, swing_progress: float) -> void:
	if _hold == null: return
	
	var dir:= FacingHelper.facing_to_string(data.facing_dir)
	sprite.position = _hold.get_offset(dir)
	sprite.z_index = -1 if dir in BEHIND else 1
	
	# Cocked back at the start and arriving at rest exactly as the swing ends,
	# so nothing snaps when is_attacking goes false. Added to the live facing
	# angle rather than baked in at swing start, so turning mid-swing carries
	# the swing round with you instead of leaving the blade pointing backwards.
	var swing:= 0.0
	if data.is_attacking:
		swing = -_swing_arc * (1.0 - swing_progress)
	
	sprite.rotation = _facing_angle(dir) + _rest_offset + swing

## Snapped to the eight facings rather than taken from facing_dir's own angle.
## facing_dir turns smoothly, and rotated pixel art looks worst at arbitrary
## angles — this keeps the weapon on the octants the art was drawn for.
func _facing_angle(dir: String) -> float:
	match dir:
		"right": return 0.0
		"down_right": return PI * 0.25
		"down": return PI * 0.5
		"down_left": return PI * 0.75
		"left": return PI
		"up_left": return -PI * 0.75
		"up": return -PI * 0.5
		"up_right": return -PI * 0.25
		_: return 0.0
