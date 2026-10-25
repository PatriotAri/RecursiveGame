class_name SpacingGrid

## Buckets every living enemy into square cells once per physics frame, so
## spacing only has to look at the cells around an enemy instead of every
## enemy in the level. Turns an n² loop into roughly n·k, where k is how many
## enemies crowd one neighbourhood.

## Cell edge in px. A spacing_radius bigger than this still works — it just
## searches more cells — but at or under it, a 3x3 block always suffices.
const CELL := 48.0

static var _frame:= -1
static var _cells: Dictionary = {}  # Vector2i -> Array[Enemy]
static var _empty: Array[Enemy] = []

static func cell_of(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL), floori(pos.y / CELL))

## The enemies in one cell this frame. Rebuilds the grid on the first call
## of a new physics frame.
static func bucket(tree: SceneTree, cell: Vector2i) -> Array[Enemy]:
	var frame := Engine.get_physics_frames()
	if frame != _frame:
		_frame = frame
		_rebuild(tree)
	return _cells.get(cell, _empty)

static func _rebuild(tree: SceneTree) -> void:
	_cells.clear()
	for node in tree.get_nodes_in_group(&"enemy"):
		var enemy := node as Enemy
		if enemy == null or enemy.data == null or enemy.data.is_dead:
			continue
		var cell := cell_of(enemy.global_position)
		var list: Array[Enemy] = _cells.get(cell, [] as Array[Enemy])
		if list.is_empty():
			_cells[cell] = list
		list.append(enemy)
