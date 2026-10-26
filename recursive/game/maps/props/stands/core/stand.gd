class_name Stand

extends Interactable

## A stand on the airship. Using it opens the stand menu (StandUi), which
## shows a list on the left and the selected entry's detail and actions on
## the right. Each kind of stand fills those in; the rules for what can be
## bought live in the player's systems.

@export var title := "Stand"
@export var gold_item: Item
@export var soul_item: Item

func _ready() -> void:
	super()
	interacted.connect(_on_interacted)

func _on_interacted(player: Node) -> void:
	var menu := get_tree().get_first_node_in_group(&"stand_ui")
	if menu == null:
		push_warning("%s: no stand menu in the scene." % name)
		return
	menu.open(self, player)

## The left column, one row per entry. Pressing a row returns the selection
## it stands for.
func list_rows(_player: Node, _selected: Variant) -> Array[StandRow]:
	return []

## The right column for `selected`. Null shows nothing.
func detail(_player: Node, _selected: Variant) -> StandDetail:
	return null

## What's selected when the menu opens, and when the selection is gone.
func first_selection(player: Node) -> Variant:
	for row in list_rows(player, null):
		if row.on_pressed.is_valid():
			return row.on_pressed.call()
	return null

## Shown in place of an empty list.
func empty_text() -> String:
	return "Nothing here."

## How many of `item` the player has.
static func count_of(player: Node, item: Item) -> int:
	return player.data.inventory.get_count(item.id) if item else 0
