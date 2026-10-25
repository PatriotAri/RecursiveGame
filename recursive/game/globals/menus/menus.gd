extends Node

## Autoloaded as Menus. The one owner of "is the game paused" and "is the
## mouse free": both are true exactly while at least one menu is open.
## Menus open and close themselves through here, instead of each juggling
## the pause and guessing which other menus might still need it.
##
## The pause key goes to the top menu: a closable one closes (through its
## own close(), so it can tidy its sub-panels); with nothing open, the pause
## menu opens. A menu opened with closable = false — the death screen —
## ignores it.

signal changed

## Set by the pause menu when it enters the game, so the pause key has
## something to open.
var pause_menu: CanvasLayer

var _stack: Array[CanvasLayer] = []
var _unclosable: Dictionary = {}  # instance id -> true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func open(menu: CanvasLayer, closable := true) -> void:
	_prune()
	if _stack.has(menu): return
	_stack.append(menu)
	if not closable:
		_unclosable[menu.get_instance_id()] = true
	menu.visible = true
	_apply()

func close(menu: CanvasLayer) -> void:
	if not _stack.has(menu): return
	_stack.erase(menu)
	_unclosable.erase(menu.get_instance_id())
	menu.visible = false
	_apply()

func is_open(menu: CanvasLayer) -> bool:
	return _stack.has(menu)

func any_open() -> bool:
	_prune()
	return not _stack.is_empty()

func top() -> CanvasLayer:
	_prune()
	return _stack.back() if not _stack.is_empty() else null

## Forgets every menu and unpauses. For leaving the game scene — main menu,
## loading, respawning — where the menus are about to be freed anyway.
func reset() -> void:
	_stack.clear()
	_unclosable.clear()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	changed.emit()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"): return
	var menu := top()
	if menu:
		if not _unclosable.has(menu.get_instance_id()):
			if menu.has_method(&"close"): menu.close()
			else: close(menu)
		get_viewport().set_input_as_handled()
	elif is_instance_valid(pause_menu):
		pause_menu.open()
		get_viewport().set_input_as_handled()

func _apply() -> void:
	var paused := not _stack.is_empty()
	get_tree().paused = paused
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CONFINED_HIDDEN)
	changed.emit()

## Drops menus freed with their scene.
func _prune() -> void:
	for i in range(_stack.size() - 1, -1, -1):
		if not is_instance_valid(_stack[i]):
			_stack.remove_at(i)
