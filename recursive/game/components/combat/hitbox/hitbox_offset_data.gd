class_name HitboxOffsetData

extends Resource

## One offset per compass facing (N, NE, E, SE, S, SW, W, NW). Look up by
## FacingHelper index with get_offset_at() in per-frame code.

@export_range(-500, 500, 0.5) var n_x: float
@export_range(-500, 500, 0.5) var n_y: float
@export_range(-500, 500, 0.5) var ne_x: float
@export_range(-500, 500, 0.5) var ne_y: float
@export_range(-500, 500, 0.5) var e_x: float
@export_range(-500, 500, 0.5) var e_y: float
@export_range(-500, 500, 0.5) var se_x: float
@export_range(-500, 500, 0.5) var se_y: float
@export_range(-500, 500, 0.5) var s_x: float
@export_range(-500, 500, 0.5) var s_y: float
@export_range(-500, 500, 0.5) var sw_x: float
@export_range(-500, 500, 0.5) var sw_y: float
@export_range(-500, 500, 0.5) var w_x: float
@export_range(-500, 500, 0.5) var w_y: float
@export_range(-500, 500, 0.5) var nw_x: float
@export_range(-500, 500, 0.5) var nw_y: float

## By FacingHelper index — what per-frame code should use.
func get_offset_at(index: int) -> Vector2:
	match index:
		FacingHelper.E: return Vector2(e_x, e_y)
		FacingHelper.SE: return Vector2(se_x, se_y)
		FacingHelper.S: return Vector2(s_x, s_y)
		FacingHelper.SW: return Vector2(sw_x, sw_y)
		FacingHelper.W: return Vector2(w_x, w_y)
		FacingHelper.NW: return Vector2(nw_x, nw_y)
		FacingHelper.N: return Vector2(n_x, n_y)
		FacingHelper.NE: return Vector2(ne_x, ne_y)
		_: return Vector2.ZERO

func get_offset(direction_string: String) -> Vector2:
	match direction_string:
		"N": return Vector2(n_x, n_y)
		"NE": return Vector2(ne_x, ne_y)
		"E": return Vector2(e_x, e_y)
		"SE": return Vector2(se_x, se_y)
		"S": return Vector2(s_x, s_y)
		"SW": return Vector2(sw_x, sw_y)
		"W": return Vector2(w_x, w_y)
		"NW": return Vector2(nw_x, nw_y)
		_: return Vector2.ZERO
