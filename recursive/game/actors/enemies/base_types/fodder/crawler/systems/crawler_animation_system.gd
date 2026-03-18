class_name CrawlerAnimationSystem

var sprite: AnimatedSprite2D
var data: EnemyData

var _last_facing: String = ""

func _init(sprite_ref: AnimatedSprite2D, data_ref: EnemyData) -> void:
	sprite = sprite_ref
	data = data_ref
	sprite.animation_finished.connect(_on_animation_finished)
	
func update() -> void:
	var animation_name:= _resolve_animation()
	if sprite.animation != animation_name:
		sprite.play(animation_name)
		
func _resolve_animation() -> StringName:
	var dir:= data.last_facing if data.last_facing != Vector2.ZERO else Vector2.DOWN
	var dir_str:= FacingHelper.facing_to_string(dir)
	
	match data.current_state:
		EnemyData.State.DIED:
			return "died"
		EnemyData.State.HURT:
			return "hurt_" + dir_str
		EnemyData.State.ATTACK:
			return "attack_" + dir_str
		EnemyData.State.CHASE, EnemyData.State.PATROL:
			return "walk_" + dir_str
		_:
			return "idle_" + dir_str

func _on_animation_finished() -> void:
	if sprite.animation.begins_with("hurt"):
		data.is_hurt = false
