class_name EnemyHealthComponent

extends HealthComponent

var data: EnemyData

func initialize(data_ref: EnemyData) -> void:
	data = data_ref

func _on_hurt() -> void:
	data.is_hurt = true
	super._on_hurt()

func _on_died() -> void:
	data.is_dead = true
	super._on_died()
