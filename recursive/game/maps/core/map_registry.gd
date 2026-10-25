class_name MapRegistry

extends Resource

## Every map the game can load. Doors and saves refer to maps by id, so a map
## can move on disk with only its entry here changing.

@export var maps: Array[MapData] = []

func find(map_id: StringName) -> MapData:
	for map in maps:
		if map != null and map.id == map_id:
			return map
	return null
