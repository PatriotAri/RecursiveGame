class_name ScrollItem

extends Item

## Teaches an enchantment when read from the inventory, and is used up.
## Refused, and kept, if it's already known. Learned enchantments go on gear
## at the armor and weapon stands, for souls. Sold at the vendor; later a rare
## find in chests.

@export var enchantment: Enchantment
@export var use_sound: SoundEffect
