class_name PlayerWeaponVisualSystem

## Facings where the weapon belongs behind the body rather than in front.
const BEHIND := ["up", "up_left", "up_right"]

var sprite: Sprite2D

var _hold: HitboxOffsetData
var _rest_offset:= 0.0

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
		sprite.texture = null
		sprite.visible = false
		return
	_hold = item.hold_offsets
	_rest_offset = deg_to_rad(item.rest_angle_degrees)
	sprite.texture = item.held_texture
	sprite.visible = true

func update(data: PlayerData) -> void:
	if _hold == null: return
	
	var dir:= FacingHelper.facing_to_string(data.facing_dir)
	sprite.position = _hold.get_offset(dir)
	# z_as_relative is on by default, so this is relative to the body sprite
	# the weapon hangs from: -1 tucks it behind, 1 puts it in front.
	sprite.z_index = -1 if dir in BEHIND else 1
	sprite.rotation = _facing_angle(dir) + _rest_offset

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
