class_name StatBonuses

extends Resource

## Flat additive bonuses from one piece of equipment. Every field is a
## delta, not a final value — zero means "this item doesn't touch that stat".
@export var max_health := 0
@export var max_stamina := 0
@export var max_mana := 0
@export var walk_speed := 0.0
@export var run_speed := 0.0

## Costs, so the sign is inverted from everything above: NEGATIVE is the
## good direction. A light weapon that makes swinging cheaper has
## attack_stamina_cost = -1, not +1.
@export var sprint_stamina_cost := 0.0
@export var attack_stamina_cost := 0

## Adds up the bonuses from several items. Returns a fresh instance rather
## than adding into the first one, because each item's bonuses are a shared
## .tres — writing to it would permanently change that item everywhere.
static func stat_total(bonuses: Array[StatBonuses]) -> StatBonuses:
	var sum := StatBonuses.new()
	for bonus in bonuses:
		if bonus == null: continue
		sum.max_health += bonus.max_health
		sum.max_stamina += bonus.max_stamina
		sum.max_mana += bonus.max_mana
		sum.walk_speed += bonus.walk_speed
		sum.run_speed += bonus.run_speed
		sum.sprint_stamina_cost += bonus.sprint_stamina_cost
		sum.attack_stamina_cost += bonus.attack_stamina_cost
	return sum
