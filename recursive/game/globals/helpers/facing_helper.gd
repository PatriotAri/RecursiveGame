class_name FacingHelper

static func facing_to_string(facing: Vector2) -> String:
	var angle := facing.angle()
	var degrees := rad_to_deg(angle)

	if degrees < 0:
		degrees += 360

	# Screen space: +y is down, so 90 degrees is south.
	if degrees >= 337.5 or degrees < 22.5:
		return "E"
	elif degrees < 67.5:
		return "SE"
	elif degrees < 112.5:
		return "S"
	elif degrees < 157.5:
		return "SW"
	elif degrees < 202.5:
		return "W"
	elif degrees < 247.5:
		return "NW"
	elif degrees < 292.5:
		return "N"
	else:
		return "NE"

## The facing on the other side of the north-south axis. West-side art is
## drawn by flipping the east side, so this is the facing a flipped frame was
## actually drawn for.
static func mirrored(direction: String) -> String:
	match direction:
		"E": return "W"
		"W": return "E"
		"NE": return "NW"
		"NW": return "NE"
		"SE": return "SW"
		"SW": return "SE"
		_: return direction
