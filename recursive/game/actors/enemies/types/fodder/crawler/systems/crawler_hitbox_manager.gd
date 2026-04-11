class_name CrawlerHitboxManager

extends HitboxManagerBase

var data: EnemyData

func _init(body_ref: CharacterBody2D, data_ref: EnemyData) -> void:
	super._init(body_ref, 16)
	data = data_ref

func get_facing() -> Vector2:
	return data.facing_dir
