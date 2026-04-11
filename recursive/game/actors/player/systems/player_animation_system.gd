class_name PlayerAnimationSystem

var sprite: AnimatedSprite2D

func _init(sprite_ref: AnimatedSprite2D) -> void:
	sprite = sprite_ref

func update(data: PlayerData) -> void:
	
	var animation_name:= _resolve_animation(data)
	
	if animation_name != sprite.animation:
		sprite.play(animation_name)

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
