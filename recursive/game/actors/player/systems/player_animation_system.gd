class_name PlayerAnimationSystem

var sprite: AnimatedSprite2D
#stores most recent animation name played
var _last_animation: String = ""

func _init(sprite_ref: AnimatedSprite2D) -> void:
	sprite = sprite_ref

func update(data: PlayerData) -> void:
	
	var animation_name := _resolve_animation(data)
	
	#if animation_name isnt equal to the last animation then
	if animation_name != _last_animation:
		#play the animation name
		sprite.play(animation_name)
		#sets the value of _last_animation to the current animation_name
		_last_animation = animation_name

#turns state + facing into an animation name string
func _resolve_animation(data: PlayerData) -> String:
	var dir := FacingHelper.facing_to_string(data.facing_dir)
	
	match data.current_state:
		PlayerData.State.WALK:
			if data.is_running:
				return "run_" + dir
			else:
				return "walk_" + dir
		PlayerData.State.ATTACK:
			return "attack_" + dir
		_:
			return "idle_" + dir
