class_name Airship

extends Node2D

## The shop between rounds, reached by the ramp at the edge of each level's
## safe zone. One airship scene serves every level of a map.

## The player used the ramp back down. The map runner handles the trip.
signal leave_requested

@export var ramp_down: Interactable
## Where the player stands after boarding.
@export var arrival: Marker2D
@export var actors: Node2D

func _ready() -> void:
	ramp_down.interacted.connect(func(_player: Node) -> void: leave_requested.emit())
