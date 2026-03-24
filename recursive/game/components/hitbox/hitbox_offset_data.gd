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

var right := Vector2(right_x, right_y)
var left:= Vector2(left_x, left_y)
var up:= Vector2(up_x, up_y)
var down:= Vector2(down_x, down_y)
var up_right:= Vector2(up_right_x, up_right_y)
var up_left:= Vector2(up_left_x, up_left_y)
var down_right:= Vector2(down_right_x, down_right_y)
var down_left:= Vector2(down_left_x, down_left_y)

func get_offset(direction_string: String) -> Vector2:
	match direction_string:
		"right": return right
		"left": return left
		"up": return up
		"down": return down
		"up_right": return up_right
		"up_left": return up_left
		"down_right": return down_right
		"down_left": return down_left
		_: return Vector2.ZERO
