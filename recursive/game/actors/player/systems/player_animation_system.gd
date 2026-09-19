class_name PlayerAnimationSystem

var sprite: AnimatedSprite2D

var _last_hurt_seq:= -1

func _init(sprite_ref: AnimatedSprite2D) -> void:
	sprite = sprite_ref

func update(data: PlayerData) -> void:
	
	var animation_name:= _resolve_animation(data)
	
	# A second hit during hitstun resolves to the same animation name, so the
	# name check below won't replay it. The counter catches that case.
	var restart:= data.current_state == PlayerData.State.HURT \
		and data.hurt_seq != _last_hurt_seq
	_last_hurt_seq = data.hurt_seq
	
	if animation_name != sprite.animation or restart:
		sprite.play(animation_name)
		if restart:
			sprite.frame = 0

#turns state + facing into an animation name string
func _resolve_animation(data: PlayerData) -> String:
	#gets name of the direction youre facing
	var dir:= FacingHelper.facing_to_string(data.facing_dir)
	
	#Gets the current player state from player data, combines with 
	#direction, and outputs the proper animation name to be called.
	match data.current_state:
		PlayerData.State.DIED:
			return "died"
		PlayerData.State.HURT:
			return "hurt_" + dir
		PlayerData.State.WALK:
			if data.is_running:
				return "run_" + dir
			else:
				return "walk_" + dir
		PlayerData.State.ATTACK:
			return "attack_" + dir
		_:
			return "idle_" + dir
