class_name PlayerAnimationSystem

var sprite: AnimatedSprite2D

func _init(sprite_ref: AnimatedSprite2D) -> void:
	sprite = sprite_ref

func update(data: PlayerData) -> void:
	
	var animation_name := _resolve_animation(data)
	
	if animation_name != sprite.animation:
		sprite.play(animation_name)

#turns state + facing into an animation name string
func _resolve_animation(data: PlayerData) -> String:
	var dir := FacingHelper.facing_to_string(data.facing_dir)
	
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
