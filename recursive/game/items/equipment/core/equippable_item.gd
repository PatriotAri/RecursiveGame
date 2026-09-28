class_name EquippableItem

extends Item

enum Slot {WEAPON, ARMOR} #always append enum, never insert in middle

## Where this goes on the body. Distinct from Item.category, which is about
## how the item is browsed — two helms and a chestplate are all ARMOR
## category but would be different slots.
@export var slot: Slot = Slot.WEAPON

## Weapons only. Registered with the hitbox manager while worn, and spawned
## by PlayerAttackSystem in place of the unarmed punch. Leave null on armour.
@export var attack: AttackSpec

## Optional on either slot. Null means this item changes no stats.
@export var bonuses: StatBonuses

@export var animation_prefix := ""

@export_group("Weapon Held")
## Drawn in the player's hand while this is equipped. Null means the item has
## no visible presence — armour, for now.
@export var held_texture: Texture2D
## Where it sits, per facing direction, relative to the body sprite's centre.
@export var hold_offsets: HitboxOffsetData
## Correction for how the texture was drawn. 0 means the art points right.
@export_range(-180.0, 180.0) var rest_angle_degrees:= 0.0
