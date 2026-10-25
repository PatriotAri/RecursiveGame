class_name EnemyAnimationSystem

extends ActorAnimator

var data: EnemyData

func _init(sprite_ref: AnimatedSprite2D, data_ref: EnemyData) -> void:
	super(sprite_ref)
	data = data_ref
	
## `attack_duration` is the swing's full length; the attack animation is
## stretched or squeezed to match it.
func update(attack_duration := 0.0) -> void:
	play_state(_resolve_animation(), data.hurt_seq,
		data.current_state == EnemyData.State.HURT,
		data.current_state == EnemyData.State.ATTACK, attack_duration)

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
