class_name Shop

extends Node2D

## A counter the player can buy from with gold. The list is data
## (ShopEntry resources); stock is tracked per shop at runtime so two shops
## sharing a list don't share their stock.

const GOLD_ID := &"gold"

@export var shop_name:= "Shop"
@export var entries: Array[ShopEntry] = []
@export var purchase_sound: SoundEffect = preload("res://game/audio/sfx/purchase.tres")
@export var denied_sound: SoundEffect = preload("res://game/audio/sfx/denied.tres")

@onready var interactable: Interactable = $Interactable

var _stock: Array[int] = []

func _ready() -> void:
	for entry in entries:
		_stock.append(entry.stock if entry else 0)
	interactable.set_prompt(shop_name)
	interactable.interacted.connect(_on_interacted)

func _on_interacted(player: Node) -> void:
	var ui := get_tree().get_first_node_in_group(&"shop_ui")
	if ui == null:
		push_warning("%s: no ShopUi in the tree." % name)
		return
	ui.open(self, player)

func stock_left(index: int) -> int:
	return _stock[index]

func can_buy(index: int, inventory: Inventory) -> bool:
	var entry := entries[index]
	if entry == null or entry.item == null: return false
	if _stock[index] == 0: return false
	return inventory.get_count(GOLD_ID) >= entry.price

## Pays and hands over one. Returns false (and buzzes) if it can't.
func buy(index: int, inventory: Inventory) -> bool:
	if not can_buy(index, inventory):
		AudioManager.play_sfx(denied_sound)
		return false
	var entry := entries[index]
	inventory.remove(GOLD_ID, entry.price)
	inventory.add(entry.item, 1)
	if _stock[index] > 0:
		_stock[index] -= 1
	AudioManager.play_sfx(purchase_sound)
	return true
