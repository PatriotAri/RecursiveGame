class_name PlayerAnimationSystem

## Facings where each arm sits behind the torso, seen from the camera, for a
## right-handed character: the arm on the far side is behind, and with the
## back to the camera both are. Each arm's armour moves with it, and the held
## weapon follows the right arm in PlayerWeaponVisualSystem.
const LEFT_ARM_BEHIND := ["SE", "E", "NE", "N", "NW"]
const RIGHT_ARM_BEHIND := ["NE", "N", "NW", "W", "SW"]
const LEFT_ARM_LAYERS: Array[StringName] = [&"LeftArm", &"LeftArmArmor"]
const RIGHT_ARM_LAYERS: Array[StringName] = [&"RightArm", &"RightArmArmor"]

var visual: LayeredSprite

var _last_hurt_seq:= -1

func _init(visual_ref: LayeredSprite) -> void:
	visual = visual_ref

func update(data: PlayerData, swing_progress := 0.0) -> void:
	var base_name:= _base_animation(data)
	var animation_name:= _resolve_animation(data, base_name)
	
	# A second hit during hitstun resolves to the same animation name, so the
	# name check in play() won't replay it. The counter catches that case.
	var restart:= data.current_state == PlayerData.State.HURT \
		and data.hurt_seq != _last_hurt_seq
	_last_hurt_seq = data.hurt_seq
	
	visual.play(animation_name, base_name, restart)
	
	# Attack frames follow the swing's own clock instead of a frame rate, so
	# the pose, the weapon arc and the hitbox can't drift apart whatever the
	# weapon's windup and lifetime are.
	if data.current_state == PlayerData.State.ATTACK:
		visual.set_progress(swing_progress)
	
	# A flipped frame was drawn for the mirrored facing, so it takes that
	# facing's order — the near arm in east-facing art stays the near arm.
	var dir:= FacingHelper.facing_to_string(data.facing_dir)
	if visual.is_mirrored():
		dir = FacingHelper.mirrored(dir)
	for layer in LEFT_ARM_LAYERS:
		visual.set_layer_z(layer, -1 if dir in LEFT_ARM_BEHIND else 0)
	for layer in RIGHT_ARM_LAYERS:
		visual.set_layer_z(layer, -1 if dir in RIGHT_ARM_BEHIND else 0)

#Applies the current stance to the unarmed animation name, where art for it
#exists. A stance can ship partly drawn — anything missing falls back to the
#unarmed version of that same state, so a half-finished set never leaves the
#player invisible or frozen.
func _resolve_animation(data: PlayerData, base: String) -> String:
	if data.animation_prefix == "":
		return base
	var armed:= data.animation_prefix + "_" + base
	if visual.has_animation(armed):
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
