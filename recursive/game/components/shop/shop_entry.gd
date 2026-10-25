class_name ShopEntry

extends Resource

## One line in a shop: an item, its price in gold, and how many there are.

@export var item: Item
@export var price:= 10
## -1 = never runs out.
@export var stock:= -1
