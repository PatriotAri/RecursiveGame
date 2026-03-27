class_name PlayerHitboxManager

extends HitboxManagerBase

var data: PlayerData

func _init(player_ref: CharacterBody2D, data_ref: PlayerData) -> void:
	super._init(player_ref, 32)
	data = data_ref

func get_facing() -> Vector2:
	return data.facing_dir
