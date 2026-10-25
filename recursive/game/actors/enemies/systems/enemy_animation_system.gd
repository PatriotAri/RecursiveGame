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

const STATE_NAMES: Array[StringName] = [&"idle", &"walk", &"attack", &"hurt"]

## (state slot * 8 + facing) -> the animation this sprite actually has for
## it. Resolved once per combination, since the sprite's frames never change.
var _resolved: Dictionary = {}

func _resolve_animation() -> StringName:
	if data.current_state == EnemyData.State.DIED:
		return &"died"
	var slot: int
	match data.current_state:
		EnemyData.State.HURT:
			slot = 3
		EnemyData.State.ATTACK:
			slot = 2
		EnemyData.State.CHASE, EnemyData.State.PATROL, EnemyData.State.FLEE:
			slot = 1
		_:
			slot = 0
	var dir:= FacingHelper.facing_index(data.facing_dir) if data.facing_dir != Vector2.ZERO else FacingHelper.S
	var key:= slot * 8 + dir
	var anim: StringName = _resolved.get(key, &"")
	if anim == &"":
		var state := STATE_NAMES[slot]
		anim = _first_existing([FacingHelper.anim(state, dir), state, FacingHelper.anim(&"idle", dir), &"idle"])
		_resolved[key] = anim
	return anim

## Not every enemy is drawn in eight directions for every state. A bat with
## one "idle" flap loop is a complete set: anything missing falls back to the
## undirected name, then to idle, instead of erroring.
func _first_existing(names: Array) -> StringName:
	for anim in names:
		if sprite.sprite_frames.has_animation(anim):
			return anim
	return names[0]
