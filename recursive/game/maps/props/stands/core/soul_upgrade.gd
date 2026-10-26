class_name SoulUpgrade

extends Resource

## One stat the soul stand raises. Each purchase adds `amount` to its base;
## the price starts at `first_cost` and goes up by `cost_increase` every
## `increase_every` purchases, so spreading souls around is cheaper than
## piling them into one stat.

enum Stat {MAX_HEALTH, MAX_STAMINA, MAX_MANA} #always append enum, never insert in middle

## Stable: saves count purchases by it.
@export var id: StringName
@export var display_name := ""
@export var stat := Stat.MAX_HEALTH
@export var amount := 2
@export var first_cost := 1
@export var cost_increase := 1
@export var increase_every := 2
@export var max_purchases := 10

## What purchase number `index` (0 for the first) costs.
func cost_of(index: int) -> int:
	return first_cost + cost_increase * (index / maxi(increase_every, 1))
