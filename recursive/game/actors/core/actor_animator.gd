class_name ActorAnimator

## Plays an actor's state animation on its body sprite. Shared by the player
## and every enemy: attack animations are fitted to the attack's length, and
## a hit during hitstun restarts the hurt animation even though its name
## didn't change.

var sprite: AnimatedSprite2D

var _last_hurt_seq:= -1

func _init(sprite_ref: AnimatedSprite2D) -> void:
	sprite = sprite_ref

func play_state(anim: StringName, hurt_seq: int, is_hurt_state: bool, is_attack_state: bool, attack_duration: float) -> void:
	if is_attack_state:
		sprite.speed_scale = AnimationTiming.speed_to_fit(sprite.sprite_frames, anim, attack_duration)
	else:
		sprite.speed_scale = 1.0
	
	# A second hit during hitstun resolves to the same animation name, so the
	# name check below won't replay it. The counter catches that case.
	var restart:= is_hurt_state and hurt_seq != _last_hurt_seq
	_last_hurt_seq = hurt_seq
	
	if anim != sprite.animation or restart:
		sprite.play(anim)
		if restart:
			sprite.frame = 0
