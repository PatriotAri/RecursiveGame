class_name PlayerWeaponVisualSystem

## Facings where the weapon belongs behind the body rather than in front.
const BEHIND := [FacingHelper.N, FacingHelper.NW, FacingHelper.NE]

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
	
	var dir:= data.facing_index
	sprite.position = _hold.get_offset_at(dir)
	sprite.z_index = -1 if dir in BEHIND else 1
	
	# Cocked back at the start and arriving at rest exactly as the swing ends,
	# so nothing snaps when is_attacking goes false. Added to the live facing
	# angle rather than baked in at swing start, so turning mid-swing carries
	# the swing round with you instead of leaving the blade pointing backwards.
	var swing:= 0.0
	if data.is_attacking:
		swing = -_swing_arc * (1.0 - swing_progress)
	
	# Snapped to the eight facings rather than taken from facing_dir's own
	# angle. facing_dir turns smoothly, and rotated pixel art looks worst at
	# arbitrary angles — this keeps the weapon on the octants it was drawn for.
	sprite.rotation = dir * (PI / 4.0) + _rest_offset + swing
