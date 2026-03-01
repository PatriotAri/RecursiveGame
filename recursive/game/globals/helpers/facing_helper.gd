class_name FacingHelper

static func facing_to_string(facing: Vector2) -> String:
	var angle := facing.angle()
	var degrees := rad_to_deg(angle)

	if degrees < 0:
		degrees += 360

	if degrees >= 337.5 or degrees < 22.5:
		return "right"
	elif degrees < 67.5:
		return "down_right"
	elif degrees < 112.5:
		return "down"
	elif degrees < 157.5:
		return "down_left"
	elif degrees < 202.5:
		return "left"
	elif degrees < 247.5:
		return "up_left"
	elif degrees < 292.5:
		return "up"
	else:
		return "up_right"
