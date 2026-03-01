class_name HealthComponent

#extended as Node, class contains logic only, no physics or rendering
extends Node

#declared signals
signal died

#health variables
@export var max_health: float = 10.0
var current_health: float

func _ready() -> void:
	#health starts at full
	current_health = max_health
	
func apply_damage(damage: float) -> void:
	#subtracts amount of damage from health, sets health to 0 if current health becomes negative
	current_health = max(current_health - damage, 0)
	print("Health is now: ", current_health)
	
	#when health reaches 0, emit signal "died"
	if current_health == 0:
		died.emit()
