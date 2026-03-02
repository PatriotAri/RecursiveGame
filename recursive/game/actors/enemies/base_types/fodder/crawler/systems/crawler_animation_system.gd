class_name CrawlerAnimationSystem

var sprite: AnimatedSprite2D
var data: EnemyData

func _init(sprite_ref: AnimatedSprite2D, data_ref: EnemyData) -> void:
	sprite = sprite_ref
	data = data_ref
	
func update() -> void:
	var animation_name:= resolve_animation()
	if sprite.animation != animation_name:
		sprite.play(animation_name)
		
func resolve_animation() -> StringName:
	var prefix: String
	match data.current_state:
		CrawlerStateMachine.State.CHASE, CrawlerStateMachine.State.PATROL:
			prefix = "walk"
		_:
			prefix = "idle"
	
	var dir:= data.last_facing if data.last_facing != Vector2.ZERO else Vector2.DOWN
	return prefix + "_" + FacingHelper.facing_to_string(dir)
