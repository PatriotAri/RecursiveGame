class_name ItemDatabase

extends Resource

## Every item in the game, looked up by id. Saves store item ids rather than
## file paths, so an item can be moved or renamed on disk without breaking
## anyone's save — only its entry here has to follow it.
##
## Add every new item .tres here.

@export var items: Array[Item] = []

func find(item_id: StringName) -> Item:
	for item in items:
		if item != null and item.id == item_id:
			return item
	return null
