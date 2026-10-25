class_name Spell

extends Resource

## One castable spell. What it does is an ordinary AttackSpec — a spell is an
## attack that costs mana (AttackSpec.mana_cost) and has a cooldown, so it
## reuses the whole hitbox/projectile pipeline instead of growing its own.

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var attack: AttackSpec
## Seconds after a cast before this spell can be cast again.
@export var cooldown := 1.0

## The name its attack is registered under with the caster's hitbox manager.
## Prefixed so a spell and a weapon can never share an id by accident.
func attack_name() -> StringName:
	return StringName("spell_" + String(id))
