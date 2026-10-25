class_name SoundEffect

extends Resource

## One named sound: a pool of interchangeable clips plus how to play them.
## Several clips and a little pitch jitter stop a sound heard twenty times a
## fight from turning into a machine gun.

@export var streams: Array[AudioStream] = []
@export_range(-40.0, 12.0, 0.5) var volume_db := 0.0
## Each play is pitched up or down by up to this fraction.
@export_range(0.0, 0.5, 0.01) var pitch_variance := 0.08
@export var bus: StringName = &"SFX"
## How many copies may sound at once. A crowd of enemies all dying on the
## same frame would otherwise stack into one very loud noise. 0 = no limit.
@export var max_instances := 4

func pick() -> AudioStream:
	if streams.is_empty(): return null
	return streams[randi() % streams.size()]

func random_pitch() -> float:
	return 1.0 + randf_range(-pitch_variance, pitch_variance)
