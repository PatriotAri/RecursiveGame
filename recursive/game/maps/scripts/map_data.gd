class_name MapData

extends Resource

## A map: its levels, in the order they're played (each one a floor further
## down), and the airship the player shops on between rounds.

@export var display_name := ""
@export var levels: Array[PackedScene] = []
@export var airship_scene: PackedScene
