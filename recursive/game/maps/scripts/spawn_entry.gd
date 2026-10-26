class_name SpawnEntry

extends Resource

## One kind of enemy an area spawns each round.

@export var enemy_scene: PackedScene
## How many on the area's first round.
@export var count := 3
## Added every time the area is fought again in a later round.
@export var extra_per_round := 1
## Upper limit, so late rounds can't flood the area.
@export var max_count := 10

## How many to spawn on the area's `visit`th round (0 = first).
func count_for_visit(visit: int) -> int:
	return mini(count + extra_per_round * maxi(visit, 0), max_count)
