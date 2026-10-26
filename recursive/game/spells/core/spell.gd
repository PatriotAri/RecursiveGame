class_name Spell

extends Resource

## A spell: learned from a tome, put on a number key from the inventory's
## Spells tab, and cast with the attack button while readied. Its attack is a
## projectile, cast from between the hands or from a held staff's tip.

## Stable, like an item id: saves refer to spells by it.
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
## Shown in the Spells tab, and in the HUD corner while readied.
@export var icon: Texture2D
## Floats in the hands, or at a staff's tip, while readied.
@export var held_texture: Texture2D
@export var attack: ProjectileAttackSpec
