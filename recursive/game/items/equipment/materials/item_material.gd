class_name ItemMaterial

extends Resource

## A material gear is made of: leather, iron, steel, damascus, ebony, glass.
## Shared by every piece made of it. What a piece is called and how strong it
## is at each material is the piece's own, in its ItemTier list.

@export var display_name := ""
## Higher is better. The armour set rule compares ranks: no worn piece can be
## more than one rank above the weakest.
@export var rank := 0
## Gold to upgrade a piece into this material at the armor or weapon stand.
@export var upgrade_cost := 0
## How many enchantments a piece made of this holds.
@export var enchant_slots := 1
## Recolours a piece whose art is drawn as another material: each pixel's
## brightness picks a colour along this, dark to light. Never used on a
## piece drawn as this material.
@export var ramp: GradientTexture1D
