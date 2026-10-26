class_name PlayerWeaponVisualSystem

## The weapon is held in this arm, so it sits on the same side of the body.
const WEAPON_ARM := &"RightArm"

## Facings where the readied spell is behind the body: back to the camera.
const SPELL_BEHIND := ["N", "NE", "NW"]
## Where a spell floats with no staff, in front of the chest, as a distance
## along the facing from this point (the visual's own space).
const HANDS_CENTRE := Vector2(0, 2)
const HANDS_REACH := 12.0

var sprite: Sprite2D
## The weapon sits in this stack's hand, frame by frame.
var visual: LayeredSprite
## The readied spell, floating in the hands or at a staff's tip.
var spell_sprite: Sprite2D

var _rest_offset:= 0.0
var _swing_arc:= 0.0
## A held staff's tip, from its texture's centre. Null when no staff.
var _cast_point: Variant = null

func _init(sprite_ref: Sprite2D, visual_ref: LayeredSprite, spell_ref: Sprite2D) -> void:
	sprite = sprite_ref
	visual = visual_ref
	spell_sprite = spell_ref
	# Start from a known state rather than trusting whatever the scene saved.
	set_weapon(null)
	set_spell(null, null)

## Called on every refresh: the readied spell (or null), and the staff it's
## held in (or null for bare hands).
func set_spell(spell: Spell, staff: EquippableItem) -> void:
	spell_sprite.texture = spell.held_texture if spell else null
	spell_sprite.visible = spell != null
	_cast_point = staff.cast_point if staff else null

## Where the readied spell is, in world space. Spells are cast from here.
func spell_point() -> Vector2:
	return spell_sprite.global_position

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
	_update_weapon(data, swing_progress)
	_update_spell(data)

## After the weapon, so a staff's tip is where the weapon was just put.
func _update_spell(data: PlayerData) -> void:
	if spell_sprite.texture == null: return
	# Gone from release until it's ready to cast again, like a thrown weapon.
	spell_sprite.visible = not data.cooling_down
	if _cast_point != null and sprite.visible:
		spell_sprite.position = sprite.transform * (sprite.offset + _cast_point)
	else:
		spell_sprite.position = HANDS_CENTRE + data.facing_dir.normalized() * HANDS_REACH
	var dir:= FacingHelper.facing_to_string(data.facing_dir)
	spell_sprite.z_index = -1 if dir in SPELL_BEHIND else 2

func _update_weapon(data: PlayerData, swing_progress: float) -> void:
	if sprite.texture == null: return
	# A thrown weapon is out of the hand from release until its cooldown
	# ends, so the empty hand shows when the next throw is ready. A staff
	# stays: it isn't what's let go of.
	sprite.visible = not data.cooling_down or _cast_point != null
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
