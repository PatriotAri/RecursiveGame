class_name Vendor

extends Interactable

## Sells `stock` for gold and buys back the player's items, through the shop
## menu. Stock never runs out.

@export var stock: Array[Item] = []
## The currency item the shop deals in.
@export var gold_item: Item
@export var purchase_sound: SoundEffect
@export var sale_sound: SoundEffect

func _ready() -> void:
	super()
	interacted.connect(_on_interacted)

func _on_interacted(player: Node) -> void:
	var shop:= get_tree().get_first_node_in_group(&"shop_ui")
	if shop == null:
		push_warning("Vendor: no shop menu in the scene.")
		return
	shop.open(self, player)
