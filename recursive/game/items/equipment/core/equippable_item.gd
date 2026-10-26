class_name EquippableItem

extends Item

## TORSO keeps ARMOR's old value, so anything saved as the single armour slot
## lands on the torso rather than shifting to a different slot.
enum Slot {WEAPON, TORSO, HELMET, ARMS, LEGS} #always append enum, never insert in middle
enum Handedness {ONE_HANDED, TWO_HANDED} #always append enum, never insert in middle
## The body layers armour art can be drawn over.
enum BodyLayer {HEAD, TORSO, LEFT_ARM, RIGHT_ARM, LEGS} #always append enum, never insert in middle

## Where this goes on the body. Distinct from Item.category, which is about
## how the item is browsed — a helmet and a torso piece are both ARMOR
## category but different slots.
@export var slot: Slot = Slot.WEAPON

## Weapons only. How many hands the weapon takes.
@export var handedness: Handedness = Handedness.ONE_HANDED

## Weapons only. Registered with the hitbox manager while worn, and spawned
## by PlayerAttackSystem in place of the unarmed punch. Leave null on armour.
@export var attack: AttackSpec

## Optional on either slot. Null means this item changes no stats.
@export var bonuses: StatBonuses

@export var animation_prefix := ""

## Armour only. The art drawn over each body layer while worn — a helmet
## covers HEAD, arm guards cover LEFT_ARM and RIGHT_ARM. Animation names must
## match the player's layers; any animation a set lacks falls back to the base
## version, then hides.
@export var overlays: Dictionary[BodyLayer, SpriteFrames] = {}

@export_group("Texture & Offsets")
## Weapons only. Drawn in the player's hand while this is equipped, at the
## hand point of whatever frame the arms are on. Null means the weapon has no
## visible presence.
@export var held_texture: Texture2D
## Correction for how the texture was drawn. 0 means the art points right.
@export_range(-180.0, 180.0) var rest_angle_degrees:= 0.0

## Where the grip sits inside the texture, from its centre. The weapon rotates
## about the sprite's origin, so this is what stops a sword pinwheeling around
## its middle. For art drawn pointing right, this is usually negative x.
@export var grip_offset:= Vector2.ZERO
## How far the weapon is cocked back at the start of a swing, in degrees.
@export_range(0.0, 180.0) var swing_arc_degrees:= 90.0
