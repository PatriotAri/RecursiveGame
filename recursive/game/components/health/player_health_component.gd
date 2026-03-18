class_name PlayerHealthComponent

extends HealthComponent

var data: PlayerData

func initialize(data_ref: PlayerData) -> void:
	data = data_ref

func _on_hurt() -> void:
	data.is_attacking = false
	data.is_hurt = true
	super._on_hurt()

func _on_died() -> void:
	data.is_dead = true
	super._on_died()
