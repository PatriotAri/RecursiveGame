class_name HitboxOffsetData

extends Resource

## One offset per compass facing (N, NE, E, SE, S, SW, W, NW), as returned by
## FacingHelper.facing_to_string().

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
