class_name ConsumableItem

extends Item

@export var effects: Array[ItemEffect] = []
## Seconds the player is locked out of acting while using this. Keep at 0.0
## until a drink animation exists — PlayerAnimationSystem builds names as
## "<state>_<dir>", and a missing animation errors instead of playing.
@export var use_time: float = 0.0
