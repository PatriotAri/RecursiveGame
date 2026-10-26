class_name SoundEffect

extends Resource

## One sound the game can play: a few interchangeable takes, one picked at
## random each time with a little pitch drift, so repeats don't sound
## mechanical. Played through Sfx.

@export var streams: Array[AudioStream] = []
@export_range(-40.0, 12.0, 0.1, "suffix:dB") var volume_db := 0.0
## Random pitch spread either side of normal, as a fraction: 0.1 is ±10%.
@export_range(0.0, 0.5, 0.01) var pitch_variation := 0.05
## Which audio bus it plays on, so it follows that volume slider.
@export var bus: StringName = &"SFX"
## How many copies may play at once. Extra plays are dropped, so a crowd of
## enemies doesn't stack the same sound into noise.
@export_range(1, 32) var max_voices := 4

func pick_stream() -> AudioStream:
	if streams.is_empty(): return null
	return streams.pick_random()

func pick_pitch() -> float:
	return 1.0 + randf_range(-pitch_variation, pitch_variation)
