class_name PlayerAnimationSystem

var sprite: AnimatedSprite2D

var _last_hurt_seq:= -1

func _init(sprite_ref: AnimatedSprite2D) -> void:
	sprite = sprite_ref

func update(data: PlayerData) -> void:
	var animation_name:= _base_animation(data)
	
	# A second hit during hitstun resolves to the same animation name, so the
	# name check below won't replay it. The counter catches that case.
	var restart:= data.current_state == PlayerData.State.HURT \
		and data.hurt_seq != _last_hurt_seq
	_last_hurt_seq = data.hurt_seq
	
	if animation_name != sprite.animation or restart:
		sprite.play(animation_name)
		if restart:
			sprite.frame = 0

#Applies the current stance to the unarmed animation name, where art for it
#exists. A stance can ship partly drawn — anything missing falls back to the
#unarmed version of that same state, so a half-finished set never leaves the
#player invisible or frozen.
func _resolve_animation(data: PlayerData) -> String:
	var base:= _base_animation(data)
	if data.animation_prefix == "":
		return base
	var armed:= data.animation_prefix + "_" + base
	if sprite.sprite_frames.has_animation(armed):
		return armed
	return base

#turns state + facing into an animation name string
func _base_animation(data: PlayerData) -> String:
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
