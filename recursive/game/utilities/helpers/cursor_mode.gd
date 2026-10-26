class_name CursorMode

## Which cursor shows. Gameplay aims with a crosshair, kept inside the window;
## menus get the normal arrow. Everything that hands control between gameplay
## and a menu goes through here, so the cursor can't be left in the wrong
## state by one screen forgetting.

const CROSSHAIR := preload("res://game/ui/cursor/crosshair.png")
## The crosshair's centre pixel: where attacks aim.
const HOTSPOT := Vector2(10, 10)

static func gameplay() -> void:
	Input.set_custom_mouse_cursor(CROSSHAIR, Input.CURSOR_ARROW, HOTSPOT)
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

static func menu() -> void:
	Input.set_custom_mouse_cursor(null)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
