class_name HitboxOffsetData

extends Resource

@export_range(-500, 500, 0.5) var right_x: float
@export_range(-500, 500, 0.5) var right_y: float
@export_range(-500, 500, 0.5) var left_x: float
@export_range(-500, 500, 0.5) var left_y: float
@export_range(-500, 500, 0.5) var up_x: float
@export_range(-500, 500, 0.5) var up_y: float
@export_range(-500, 500, 0.5)var down_x: float
@export_range(-500, 500, 0.5)var down_y: float
@export_range(-500, 500, 0.5)var up_right_x: float
@export_range(-500, 500, 0.5)var up_right_y: float
@export_range(-500, 500, 0.5)var up_left_x: float
@export_range(-500, 500, 0.5)var up_left_y: float
@export_range(-500, 500, 0.5)var down_right_x: float
@export_range(-500, 500, 0.5)var down_right_y: float
@export_range(-500, 500, 0.5)var down_left_x: float
@export_range(-500, 500, 0.5)var down_left_y: float

func get_offset(direction_string: String) -> Vector2:
	match direction_string:
		"right": return Vector2(right_x, right_y)
		"left": return Vector2(left_x, left_y)
		"up": return Vector2(up_x, up_y)
		"down": return Vector2(down_x, down_y)
		"up_right": return Vector2(up_right_x, up_right_y)
		"up_left": return Vector2(up_left_x, up_left_y)
		"down_right": return Vector2(down_right_x, down_right_y)
		"down_left": return Vector2(down_left_x, down_left_y)
		_: return Vector2.ZERO
