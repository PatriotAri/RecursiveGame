extends Node

## Autoloaded as AudioManager. Owns bus volumes, their persistence, and music.
## Everything that makes a sound picks one of the BUS_ names below rather than
## typing a bus string, so a renamed bus is one edit here.

const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const BUS_UI := &"UI"
## The order the settings menu lists them in.
const BUSES: Array[StringName] = [BUS_MASTER, BUS_MUSIC, BUS_SFX, BUS_UI]

const SETTINGS_PATH := "user://settings.cfg"
const SETTINGS_SECTION := "audio"

## Positional sounds fade out past this many pixels from the camera.
const SFX_MAX_DISTANCE := 900.0

## Two players so a new track can fade in while the old one fades out.
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_current: AudioStreamPlayer
var _music_tweens: Array[Tween] = []

## SoundEffect -> how many of its players are still sounding.
var _playing_counts: Dictionary = {}

func _ready() -> void:
	# Menus pause the tree; music and UI clicks shouldn't stop with it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_a = _make_music_player()
	_music_b = _make_music_player()
	_music_current = _music_a
	load_settings()
	# Every button in the game clicks without each menu wiring it up.
	get_tree().node_added.connect(_on_node_added)

# --- volume ---------------------------------------------------------------

## Linear 0..1, which is what a slider wants. Stored on the bus in dB.
func set_bus_volume(bus: StringName, linear: float) -> void:
	var index := _bus_index(bus)
	if index < 0: return
	linear = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(linear))
	# linear_to_db(0) is -inf, which the server accepts but still mixes.
	# Muting at zero makes "off" actually off.
	AudioServer.set_bus_mute(index, linear <= 0.0)

func get_bus_volume(bus: StringName) -> float:
	var index := _bus_index(bus)
	if index < 0: return 0.0
	if AudioServer.is_bus_mute(index): return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(index)), 0.0, 1.0)

func _bus_index(bus: StringName) -> int:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		push_warning("AudioManager: no bus named '%s' — check default_bus_layout.tres." % bus)
	return index

# --- persistence ----------------------------------------------------------

func save_settings() -> void:
	var config := ConfigFile.new()
	# Load first so saving audio doesn't wipe any other section in the file.
	config.load(SETTINGS_PATH)
	for bus in BUSES:
		config.set_value(SETTINGS_SECTION, String(bus), get_bus_volume(bus))
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("AudioManager: couldn't save settings (error %d)." % err)

func load_settings() -> void:
	var config := ConfigFile.new()
	# A missing file is the normal first-launch case, not an error.
	if config.load(SETTINGS_PATH) != OK: return
	for bus in BUSES:
		if config.has_section_key(SETTINGS_SECTION, String(bus)):
			set_bus_volume(bus, float(config.get_value(SETTINGS_SECTION, String(bus))))

# --- sound effects --------------------------------------------------------

## Plays a one-shot. Pass a world position for a sound that should come from
## somewhere (panned and quieter with distance); leave it out for one that
## should always sound the same, like UI. Returns false if it was skipped.
func play_sfx(effect: SoundEffect, at: Variant = null) -> bool:
	if effect == null: return false
	var stream := effect.pick()
	if stream == null: return false
	if effect.max_instances > 0 and _playing_counts.get(effect, 0) >= effect.max_instances:
		return false
	
	var player: Node
	if at is Vector2:
		var p2d := AudioStreamPlayer2D.new()
		p2d.max_distance = SFX_MAX_DISTANCE
		p2d.position = at
		p2d.stream = stream
		p2d.volume_db = effect.volume_db
		p2d.pitch_scale = effect.random_pitch()
		p2d.bus = effect.bus
		p2d.finished.connect(_on_sfx_finished.bind(p2d, effect))
		player = p2d
	else:
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.volume_db = effect.volume_db
		p.pitch_scale = effect.random_pitch()
		p.bus = effect.bus
		p.finished.connect(_on_sfx_finished.bind(p, effect))
		player = p
	
	# World sounds stop with the game when it pauses; UI sounds don't, or
	# clicking a pause-menu button would be silent.
	player.process_mode = Node.PROCESS_MODE_ALWAYS if effect.bus == BUS_UI else Node.PROCESS_MODE_PAUSABLE
	# Parented here rather than to whoever asked, so a sound outlives the
	# enemy whose death it is.
	add_child(player)
	player.play()
	_playing_counts[effect] = _playing_counts.get(effect, 0) + 1
	return true

func _on_sfx_finished(player: Node, effect: SoundEffect) -> void:
	_playing_counts[effect] = maxi(_playing_counts.get(effect, 1) - 1, 0)
	player.queue_free()

func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button == null: return
	# Opt-out per button with set_meta("silent", true).
	button.pressed.connect(func():
		if not button.get_meta(&"silent", false):
			play_sfx(GlobalSounds.ui_click))

# --- music ----------------------------------------------------------------

## Crossfades to `stream`. Asking for the track that's already playing does
## nothing, so a level can call this on every load without restarting it.
func play_music(stream: AudioStream, fade_time := 1.0) -> void:
	if stream == null:
		stop_music(fade_time)
		return
	if _music_current.playing and _music_current.stream == stream:
		return
	var outgoing := _music_current
	var incoming := _music_b if outgoing == _music_a else _music_a
	_kill_music_tweens()
	incoming.stream = stream
	incoming.volume_db = linear_to_db(0.0) if fade_time > 0.0 else 0.0
	incoming.play()
	_music_current = incoming
	_fade(incoming, 1.0, fade_time)
	if outgoing.playing:
		_fade(outgoing, 0.0, fade_time, true)

func stop_music(fade_time := 1.0) -> void:
	_kill_music_tweens()
	if _music_current.playing:
		_fade(_music_current, 0.0, fade_time, true)

func _fade(player: AudioStreamPlayer, to_linear: float, time: float, stop_after := false) -> void:
	if time <= 0.0:
		player.volume_db = linear_to_db(to_linear)
		if stop_after: player.stop()
		return
	var tween := create_tween()
	# Tweened in linear space: a dB tween sounds like it holds, then drops off
	# a cliff at the end.
	tween.tween_method(func(v: float): player.volume_db = linear_to_db(v),
		db_to_linear(player.volume_db), to_linear, time)
	if stop_after:
		tween.tween_callback(player.stop)
	_music_tweens.append(tween)

func _kill_music_tweens() -> void:
	for tween in _music_tweens:
		if tween.is_valid(): tween.kill()
	_music_tweens.clear()

func _make_music_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = BUS_MUSIC
	add_child(player)
	return player
