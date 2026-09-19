class_name CrawlerAnimationSystem

var sprite: AnimatedSprite2D
var data: EnemyData

var _last_hurt_seq:= -1

func _init(sprite_ref: AnimatedSprite2D, data_ref: EnemyData) -> void:
	sprite = sprite_ref
	data = data_ref
	
func update() -> void:
	var animation_name:= _resolve_animation()
	
	# A second hit during hitstun resolves to the same animation name, so the
	# name check below won't replay it. The counter catches that case.
	var restart:= data.current_state == EnemyData.State.HURT \
		and data.hurt_seq != _last_hurt_seq
	_last_hurt_seq = data.hurt_seq
	
	if sprite.animation != animation_name or restart:
		sprite.play(animation_name)
		if restart:
			sprite.frame = 0
		
func _resolve_animation() -> StringName:
	var dir:= data.facing_dir if data.facing_dir != Vector2.ZERO else Vector2.DOWN
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
