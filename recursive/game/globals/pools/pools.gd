extends Node

## Autoloaded as Pools. Keeps finished scene instances — hitboxes and
## projectiles — to hand out again, instead of instancing a fresh scene for
## every swing and freeing it after. Returned nodes wait here outside the
## tree; whatever is still pooled at exit is freed with this node.

## Past this many idle instances of one scene, extras are freed instead.
const MAX_IDLE_PER_SCENE := 64

var _idle: Dictionary = {}  # scene path -> Array[Node]

## A ready-to-use instance of `scene`: a returned one if there is one, else
## a new one. The caller resets whatever state it needs.
func acquire(scene: PackedScene) -> Node:
	var list: Array = _idle.get(scene.resource_path, [])
	while not list.is_empty():
		var node: Node = list.pop_back()
		if is_instance_valid(node):
			return node
	var node := scene.instantiate()
	node.set_meta(&"pool_key", scene.resource_path)
	return node

## Takes a node back. It must already be out of the tree. Anything that
## didn't come from acquire() is simply freed.
func release(node: Node) -> void:
	var key: String = node.get_meta(&"pool_key", "")
	var list: Array = _idle.get(key, [])
	# After _exit_tree (quitting) nothing would free a node kept now.
	if key == "" or list.size() >= MAX_IDLE_PER_SCENE or not is_inside_tree():
		node.queue_free()
		return
	if list.is_empty():
		_idle[key] = list
	list.append(node)

func idle_count(scene: PackedScene) -> int:
	return _idle.get(scene.resource_path, []).size()

func _exit_tree() -> void:
	for list in _idle.values():
		for node in list:
			if is_instance_valid(node):
				node.free()
	_idle.clear()
