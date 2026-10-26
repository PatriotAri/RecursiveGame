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
## Its numbers at level I.
@export var attack: ProjectileAttackSpec
## Levels II and up, in order, researched at the tome stand.
@export var levels: Array[SpellLevel] = []

const NUMERALS := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

func max_level() -> int:
	return 1 + levels.size()

## Its attack at `level`: `attack` itself at level I, else a copy with that
## level's numbers.
func attack_at(level: int) -> ProjectileAttackSpec:
	if level <= 1 or levels.is_empty():
		return attack
	var step := levels[mini(level, max_level()) - 2]
	var copy := attack.duplicate() as ProjectileAttackSpec
	copy.damage = step.damage
	copy.blast_radius = step.blast_radius
	copy.mana_cost = step.mana_cost
	return copy

## "Fireball II". Just its name if it has no levels to research.
func name_at(level: int) -> String:
	if levels.is_empty(): return display_name
	return "%s %s" % [display_name, NUMERALS[clampi(level, 1, NUMERALS.size()) - 1]]
