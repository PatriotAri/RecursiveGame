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

## Magic it's made with, like a staff's fire boost. These take no slot and
## can't be changed; ones added at a stand are in added_enchantments.
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

@export_group("Materials")
## What it's upgraded through at the armor or weapon stand, first to last.
## Its art is drawn as the first; the rest recolour it. Empty: it has no
## materials, like a staff.
@export var tiers: Array[ItemTier] = []
## Only pixels this grey or greyer are recoloured, so a sword's wooden grip
## stays wood while its blade changes. 1 recolours everything.
@export_range(0.0, 1.0) var recolor_max_saturation := 1.0
## Enchantment slots when it has no materials. Otherwise its material's.
@export var enchant_slots := 1

# Per-item state. An original item is shared by everyone who has one, so
# this only ever changes on a copy made with make_copy().

## Which of `tiers` it's made of now.
var tier := 0
## Enchantments added at a stand, one per slot, in slot order.
var added_enchantments: Array[Enchantment] = []
## The original this was copied from, for saves. Empty on an original.
var base_id: StringName = &""

## A copy with its own state, under a new id, so it can be upgraded or
## enchanted without changing every other one.
func make_copy(copy_id: StringName) -> EquippableItem:
	var copy := duplicate() as EquippableItem
	copy.id = copy_id
	copy.base_id = base_id if is_copy() else id
	copy.tier = tier
	copy.added_enchantments = added_enchantments.duplicate()
	return copy

func is_copy() -> bool:
	return base_id != &""

func has_materials() -> bool:
	return not tiers.is_empty()

func current_tier() -> ItemTier:
	return tiers[tier] if tier < tiers.size() else null

## The next step up, or null at the top or with no materials.
func next_tier() -> ItemTier:
	return tiers[tier + 1] if tier + 1 < tiers.size() else null

## Moves it to `new_tier`, taking that tier's name and description. Its value
## grows by each upgrade's cost, so selling it back returns half the gold
## spent. Copies only.
func set_tier(new_tier: int) -> void:
	new_tier = clampi(new_tier, 0, tiers.size() - 1)
	for i in range(tier + 1, new_tier + 1):
		value += tiers[i].material.upgrade_cost
	tier = new_tier
	var step := current_tier()
	if step == null: return
	if step.display_name != "":
		display_name = step.display_name
	if step.description != "":
		description = step.description

func slot_count() -> int:
	var step := current_tier()
	return step.material.enchant_slots if step and step.material else enchant_slots

## Built-in enchantments, then the ones added at a stand.
func all_enchantments() -> Array[Enchantment]:
	var result: Array[Enchantment] = enchantments.duplicate()
	result.append_array(added_enchantments)
	return result

func is_enchanted() -> bool:
	return not enchantments.is_empty() or not added_enchantments.is_empty()

## Its description, then what it's made of, its damage or armour, its
## enchantment slots, and its enchantments.
func details() -> String:
	var lines := PackedStringArray([description, ""])
	var step := current_tier()
	if step and step.material:
		lines.append("Made of %s." % step.material.display_name.to_lower())
	if slot == Slot.WEAPON:
		if attack and not casting_focus:
			lines.append("%s damage." % String.num(attack.damage * damage_scale()))
	else:
		var worn_bonuses := get_bonuses()
		lines.append("%d armour." % (worn_bonuses.armor if worn_bonuses else 0))
	lines.append("Enchantment slots: %d of %d used." % [added_enchantments.size(), slot_count()])
	if is_enchanted():
		lines.append_array(["", "Enchanted:"])
		for enchantment in all_enchantments():
			if enchantment: lines.append(enchantment.describe())
	return "\n".join(lines)

## Its stat bonuses with its tier's armour, or null if it changes no stats.
## A fresh copy when the tier decides the armour: `bonuses` is shared.
func get_bonuses() -> StatBonuses:
	var step := current_tier()
	if step == null or slot == Slot.WEAPON:
		return bonuses
	var result := bonuses.duplicate() as StatBonuses if bonuses else StatBonuses.new()
	result.armor = step.armor
	return result

## What its attack's damage is multiplied by at its tier.
func damage_scale() -> float:
	var step := current_tier()
	if step == null or attack == null or attack.damage <= 0.0 or step.damage <= 0.0:
		return 1.0
	return step.damage / attack.damage

## The colour ramp its art is recoloured with, or null when it's drawn as
## what it's made of.
func recolor_ramp() -> GradientTexture1D:
	var step := current_tier()
	if step == null or step.material == null or step.material == tiers[0].material:
		return null
	return step.material.ramp
