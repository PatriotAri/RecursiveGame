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
