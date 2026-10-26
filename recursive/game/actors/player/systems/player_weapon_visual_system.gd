class_name PlayerWeaponVisualSystem

## The weapon is held in this arm, so it sits on the same side of the body.
const WEAPON_ARM := &"RightArm"

var sprite: Sprite2D
## The weapon sits in this stack's hand, frame by frame.
var visual: LayeredSprite

var _rest_offset:= 0.0
var _swing_arc:= 0.0

func _init(sprite_ref: Sprite2D, visual_ref: LayeredSprite) -> void:
	sprite = sprite_ref
	visual = visual_ref
	# Start from a known state rather than trusting whatever the scene saved.
	set_weapon(null)

## Called by equipment on every weapon-slot change, unequipping included.
func set_weapon(item: EquippableItem) -> void:
	# An item with no texture can't be drawn, so it's treated the same as no
	# item.
	if item == null or item.held_texture == null:
		_rest_offset = 0.0
		_swing_arc = 0.0
		sprite.offset = Vector2.ZERO
		sprite.texture = null
		sprite.visible = false
		return
	_rest_offset = deg_to_rad(item.rest_angle_degrees)
	_swing_arc = deg_to_rad(item.swing_arc_degrees)
	sprite.offset = item.grip_offset
	sprite.texture = item.held_texture
	sprite.visible = true

func update(data: PlayerData, swing_progress: float) -> void:
	if sprite.texture == null: return
	# A thrown weapon is out of the hand from release until its cooldown
	# ends, so the empty hand shows when the next throw is ready.
	sprite.visible = not data.weapon_thrown
	if not sprite.visible: return
	
	var dir:= FacingHelper.facing_to_string(data.facing_dir)
	var mirrored:= visual.is_mirrored()
	if mirrored:
		dir = FacingHelper.mirrored(dir)
	# Wherever the arm art put the hand this frame. The weapon moves with the
	# swing animation instead of floating at a fixed offset per facing.
	sprite.position = visual.hand_point()
	sprite.z_index = -1 if visual.get_layer_z(WEAPON_ARM) < 0 else 1
	
	# Cocked back at the start and arriving at rest exactly as the swing ends,
	# so nothing snaps when is_attacking goes false. Added to the live facing
	# angle rather than baked in at swing start, so turning mid-swing carries
	# the swing round with you instead of leaving the blade pointing backwards.
	var swing:= 0.0
	if data.is_attacking:
		swing = -_swing_arc * (1.0 - swing_progress)
	
	# A flipped frame flips the weapon with it. Mirroring across the vertical
	# axis negates the rotation and the x scale.
	var angle:= _facing_angle(dir) + _rest_offset + swing
	sprite.rotation = -angle if mirrored else angle
	sprite.scale.x = -1.0 if mirrored else 1.0

## Snapped to the eight facings rather than taken from facing_dir's own angle.
## facing_dir turns smoothly, and rotated pixel art looks worst at arbitrary
## angles — this keeps the weapon on the octants the art was drawn for.
func _facing_angle(dir: String) -> float:
	match dir:
		"E": return 0.0
		"SE": return PI * 0.25
		"S": return PI * 0.5
		"SW": return PI * 0.75
		"W": return PI
		"NW": return -PI * 0.75
		"N": return -PI * 0.5
		"NE": return -PI * 0.25
		_: return 0.0
