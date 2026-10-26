class_name ItemRegistry

## Finds any item by its stable id, so saves can store ids instead of file
## paths and an item file can be moved without breaking old saves. Built on
## first use by scanning the item folders for Item resources.

## Folders searched for items, recursively.
const ROOTS := ["res://game/items", "res://game/debug"]

static var _items: Dictionary = {}  # StringName id -> Item
static var _built := false

static func get_item(id: StringName) -> Item:
	_build()
	return _items.get(id)

static func _build() -> void:
	if _built: return
	_built = true
	for root in ROOTS:
		_scan(root)

static func _scan(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null: return
	for sub in dir.get_directories():
		_scan(path.path_join(sub))
	for file in dir.get_files():
		# Exported builds list converted resources as "<name>.tres.remap";
		# loading the original path still works through the remap.
		file = file.trim_suffix(".remap")
		if not file.ends_with(".tres"): continue
		var resource := load(path.path_join(file))
		if not resource is Item: continue
		var item := resource as Item
		if item.id == &"":
			push_warning("ItemRegistry: %s has no id and can't be saved." % item.resource_path)
		elif _items.has(item.id) and _items[item.id] != item:
			push_warning("ItemRegistry: id '%s' is used by both %s and %s." % [item.id, _items[item.id].resource_path, item.resource_path])
		else:
			_items[item.id] = item
