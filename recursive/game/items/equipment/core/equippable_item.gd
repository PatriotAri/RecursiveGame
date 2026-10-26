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

## Played when it's put on. Leave empty for the shared equip sound.
@export var equip_sound: SoundEffect

## Weapons only. How many hands the weapon takes.
@export var handedness: Handedness = Handedness.ONE_HANDED

## Weapons only. Registered with the hitbox manager while worn, and spawned
## by PlayerAttackSystem in place of the unarmed punch. Leave null on armour.
@export var attack: AttackSpec

## Optional on either slot. Null means this item changes no stats.
@export var bonuses: StatBonuses

## The item's magic: elemental boosts, stat percentages, pierce. Any at all
## makes it enchanted. Added at the armor and weapon stands from v0.11.0.0.
@export var enchantments: Array[Enchantment] = []

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

## How far the texture is shifted so its grip lands on the hand: the opposite
## of where the grip sits from the texture's centre. The weapon rotates about
## the sprite's origin, so this is what stops a sword pinwheeling around its
## middle. For art drawn pointing right, with the grip on the left, this is
## usually positive x.
@export var grip_offset:= Vector2.ZERO
## How far the weapon is cocked back at the start of a swing, in degrees.
@export_range(0.0, 180.0) var swing_arc_degrees:= 90.0

@export_group("Staff")
## A staff: casting-only, with no melee of its own. A spell readied while
## it's held is amplified by the numbers below.
@export var casting_focus := false
@export var amplify_damage := 1.0
## Scales a spell's blast.
@export var amplify_area := 1.0
## Scales a spell's mana cost, rounded up.
@export var amplify_mana := 1.0
## Where a readied spell sits, from the held texture's centre: the staff's
## tip. Spells are cast from there.
@export var cast_point := Vector2.ZERO

func is_enchanted() -> bool:
	return not enchantments.is_empty()
