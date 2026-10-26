class_name HitboxOffsetData

extends Resource

@export_range(-500, 500, 0.5) var E_x: float
@export_range(-500, 500, 0.5) var E_y: float
@export_range(-500, 500, 0.5) var W_x: float
@export_range(-500, 500, 0.5) var W_y: float
@export_range(-500, 500, 0.5) var N_x: float
@export_range(-500, 500, 0.5) var N_y: float
@export_range(-500, 500, 0.5) var S_x: float
@export_range(-500, 500, 0.5) var S_y: float
@export_range(-500, 500, 0.5) var NE_x: float
@export_range(-500, 500, 0.5) var NE_y: float
@export_range(-500, 500, 0.5) var NW_x: float
@export_range(-500, 500, 0.5) var NW_y: float
@export_range(-500, 500, 0.5) var SE_x: float
@export_range(-500, 500, 0.5) var SE_y: float
@export_range(-500, 500, 0.5) var SW_x: float
@export_range(-500, 500, 0.5) var SW_y: float

func get_offset(direction_string: String) -> Vector2:
	match direction_string:
		"E": return Vector2(E_x, E_y)
		"W": return Vector2(W_x, W_y)
		"N": return Vector2(N_x, N_y)
		"S": return Vector2(S_x, S_y)
		"NE": return Vector2(NE_x, NE_y)
		"NW": return Vector2(NW_x, NW_y)
		"SE": return Vector2(SE_x, SE_y)
		"SW": return Vector2(SW_x, SW_y)
		_: return Vector2.ZERO
