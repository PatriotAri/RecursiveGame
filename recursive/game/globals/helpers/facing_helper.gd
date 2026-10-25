class_name FacingHelper

## Facing as one of eight compass sectors. Everything per-frame works with
## the sector's index (0 = E, then clockwise on screen: SE, S, SW, W, NW, N,
## NE) and looks names up in tables, so no actor builds strings every frame.

const NAMES: Array[String] = ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]

const E := 0
const SE := 1
const S := 2
const SW := 3
const W := 4
const NW := 5
const N := 6
const NE := 7

## Sector boundaries sit halfway between compass points (22.5° either side).
static func facing_index(facing: Vector2) -> int:
	return posmod(floori((facing.angle() + PI / 8.0) / (PI / 4.0)), 8)

static func facing_to_string(facing: Vector2) -> String:
	return NAMES[facing_index(facing)]

## prefix -> the eight "<prefix>_<dir>" animation names.
static var _anim_names: Dictionary = {}

## "<prefix>_<direction>" as a StringName, built once per prefix and then
## looked up — e.g. anim(&"walk", FacingHelper.SW) is &"walk_SW".
static func anim(prefix: StringName, index: int) -> StringName:
	var names: Array = _anim_names.get(prefix, [])
	if names.is_empty():
		for dir in NAMES:
			names.append(StringName(String(prefix) + "_" + dir))
		_anim_names[prefix] = names
	return names[index]
