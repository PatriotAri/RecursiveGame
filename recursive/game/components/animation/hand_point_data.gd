class_name HandPointData

extends Resource

## Where the weapon hand is on every frame of every animation, in pixels from
## the centre of the frame. Lives beside the art it describes: redraw an arm
## and its points here move with it.

## Animation name -> one point per frame. A list shorter than the animation
## repeats its last point.
@export var points: Dictionary[StringName, PackedVector2Array] = {}

func get_point(animation: StringName, frame: int) -> Vector2:
	var frame_points: PackedVector2Array = points.get(animation, PackedVector2Array())
	if frame_points.is_empty():
		return Vector2.ZERO
	return frame_points[clampi(frame, 0, frame_points.size() - 1)]

func has_animation(animation: StringName) -> bool:
	return points.has(animation)
