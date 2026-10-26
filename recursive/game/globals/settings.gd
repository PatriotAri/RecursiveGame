extends Node

## Player settings that outlive a session. Autoloaded as Settings, so they're
## loaded and applied before any scene runs — including a level launched
## straight from the editor. Saved to user://, the per-player save folder.

const PATH := "user://settings.cfg"
## Every bus with a volume slider, in the order the settings menu lists them.
## Must match the names in default_bus_layout.tres.
const AUDIO_BUSES: Array[StringName] = [&"Master", &"Music", &"SFX", &"UI", &"Ambient"]
const DEFAULT_VOLUME := 1.0

var _config := ConfigFile.new()

func _ready() -> void:
	# A missing file just means a first run; every getter falls back to its
	# default.
	var error := _config.load(PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("Settings: couldn't read %s (error %d). Using defaults." % [PATH, error])
	for bus in AUDIO_BUSES:
		_apply_volume(bus, get_volume(bus))

## Linear volume, 0 (silent) to 1 (full).
func get_volume(bus: StringName) -> float:
	return clampf(float(_config.get_value("audio", String(bus), DEFAULT_VOLUME)), 0.0, 1.0)

## Applies straight away. Call save() to keep it for next session.
func set_volume(bus: StringName, linear: float) -> void:
	linear = clampf(linear, 0.0, 1.0)
	_config.set_value("audio", String(bus), linear)
	_apply_volume(bus, linear)

func save() -> void:
	var error := _config.save(PATH)
	if error != OK:
		push_warning("Settings: couldn't write %s (error %d)." % [PATH, error])

func _apply_volume(bus: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		push_warning("Settings: no audio bus named '%s'." % bus)
		return
	# Zero mutes rather than asking for -inf dB.
	AudioServer.set_bus_mute(index, linear <= 0.0)
	if linear > 0.0:
		AudioServer.set_bus_volume_db(index, linear_to_db(linear))
