class_name ContentRegistry

## Finds any item, spell or learnable enchantment by its stable id, so saves
## can store ids instead of file paths and a file can be moved without
## breaking old saves. Built on first use by scanning the content folders for
## Item and Spell resources; learnable enchantments are the ones on scrolls.

## Folders searched, recursively.
const ROOTS := ["res://game/items", "res://game/spells", "res://game/debug"]

static var _items: Dictionary = {}  # StringName id -> Item
static var _spells: Dictionary = {}  # StringName id -> Spell
static var _enchantments: Dictionary = {}  # StringName id -> Enchantment
static var _built := false

static func get_item(id: StringName) -> Item:
	_build()
	return _items.get(id)

static func get_spell(id: StringName) -> Spell:
	_build()
	return _spells.get(id)

static func get_enchantment(id: StringName) -> Enchantment:
	_build()
	return _enchantments.get(id)

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
		if resource is Item:
			_register(_items, resource)
			if resource is ScrollItem and resource.enchantment:
				_register(_enchantments, resource.enchantment)
		elif resource is Spell:
			_register(_spells, resource)

static func _register(table: Dictionary, resource: Resource) -> void:
	var id: StringName = resource.id
	if id == &"":
		push_warning("ContentRegistry: %s has no id and can't be saved." % resource.resource_path)
	elif table.has(id) and table[id] != resource:
		push_warning("ContentRegistry: id '%s' is used by both %s and %s." % [id, table[id].resource_path, resource.resource_path])
	else:
		table[id] = resource
