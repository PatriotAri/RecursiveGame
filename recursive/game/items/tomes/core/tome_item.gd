class_name TomeItem

extends Item

## Teaches a spell when used from the inventory, and is used up. Refused,
## and kept, if the spell is already known. Sold at the vendor; later found as
## loot and researched at the tome stand.

@export var spell: Spell
@export var use_sound: SoundEffect
