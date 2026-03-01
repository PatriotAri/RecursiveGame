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
	return prefix + "_" + dir_suffix(dir)
	
static func dir_suffix(dir: Vector2) -> String:
	var sector:= roundi(dir.angle() / (PI / 4.0))
	match sector:
		0:	return "right"
		1:	return "down_right"
		2:	return "down"
		3:	return "down_left"
		4, -4:	return "left"
		-3:	return "up_left"
		-2:	return "up"
		_:	return "up_right" #-1
