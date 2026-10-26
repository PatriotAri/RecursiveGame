class_name ItemTier

extends Resource

## One step on a piece's material ladder: what it's called and how strong it
## is when made of `material`. A piece's art is drawn as its first tier.

@export var material: ItemMaterial
@export var display_name := ""
## Replaces the item's description at this tier. Empty keeps it.
@export_multiline var description := ""
## Armour only: armour points at this tier.
@export var armor := 0
## Weapons only: damage per hit at this tier.
@export var damage := 0.0
