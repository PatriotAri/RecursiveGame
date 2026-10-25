class_name AnimationTiming

## Fits animations to gameplay timing. An attack is decided by its windup and
## lifetime, not by how many frames somebody drew, so the attack animation is
## sped up or slowed down to end exactly when the attack does.

## How long one pass through `anim` takes at speed_scale 1, in seconds.
static func natural_length(frames: SpriteFrames, anim: StringName) -> float:
	if frames == null or not frames.has_animation(anim): return 0.0
	var fps := frames.get_animation_speed(anim)
	if fps <= 0.0: return 0.0
	var units := 0.0
	for i in frames.get_frame_count(anim):
		units += frames.get_frame_duration(anim, i)
	return units / fps

## The speed_scale that makes `anim` last `duration` seconds. Clamped so a
## near-zero duration doesn't blur the animation into nothing.
static func speed_to_fit(frames: SpriteFrames, anim: StringName, duration: float) -> float:
	var length := natural_length(frames, anim)
	if length <= 0.0 or duration <= 0.0: return 1.0
	return clampf(length / duration, 0.25, 4.0)
