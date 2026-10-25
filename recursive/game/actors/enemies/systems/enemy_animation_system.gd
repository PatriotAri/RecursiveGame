class_name EnemyAnimationSystem

var sprite: AnimatedSprite2D
var data: EnemyData

var _last_hurt_seq:= -1

func _init(sprite_ref: AnimatedSprite2D, data_ref: EnemyData) -> void:
	sprite = sprite_ref
	data = data_ref
	
## `attack_duration` is the swing's full length; the attack animation is
## stretched or squeezed to match it.
func update(attack_duration := 0.0) -> void:
	var animation_name:= _resolve_animation()
	if data.current_state == EnemyData.State.ATTACK:
		sprite.speed_scale = AnimationTiming.speed_to_fit(sprite.sprite_frames, animation_name, attack_duration)
	else:
		sprite.speed_scale = 1.0
	
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
	
	var state: String
	match data.current_state:
		EnemyData.State.DIED:
			return "died"
		EnemyData.State.HURT:
			state = "hurt"
		EnemyData.State.ATTACK:
			state = "attack"
		EnemyData.State.CHASE, EnemyData.State.PATROL, EnemyData.State.FLEE:
			state = "walk"
		_:
			state = "idle"
	return _first_existing([state + "_" + dir_str, state, "idle_" + dir_str, "idle"])

## Not every enemy is drawn in eight directions for every state. A bat with
## one "idle" flap loop is a complete set: anything missing falls back to the
## undirected name, then to idle, instead of erroring.
func _first_existing(names: Array) -> StringName:
	for anim in names:
		if sprite.sprite_frames.has_animation(anim):
			return anim
	return names[0]
