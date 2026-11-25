## Generates all music and sound effects at runtime so the project needs
## no paid or copyrighted audio files. Uses tiny procedural chiptune synths.
extends Node

const RATE := 22050
const MUSIC_BEAT := 0.42

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _music_stream: AudioStreamWAV

var _music_volume := 0.65
var _sfx_volume := 0.85


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

	for i in 8:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		add_child(player)
		_sfx_players.append(player)

	_build_sound_effects()
	_music_stream = _build_music()

	set_music_volume(GameManager.music_volume if is_instance_valid(GameManager) else 0.65)
	set_sfx_volume(GameManager.sfx_volume if is_instance_valid(GameManager) else 0.85)
	play_music()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
func play_sfx(sound_name: String) -> void:
	if _sfx_volume <= 0.001:
		return
	if not _sfx_cache.has(sound_name):
		return
	var chosen: AudioStreamPlayer = _sfx_players[0]
	for player in _sfx_players:
		if not player.playing:
			chosen = player
			break
	chosen.stream = _sfx_cache[sound_name]
	chosen.volume_db = linear_to_db(maxf(0.0001, _sfx_volume)) - 3.0
	chosen.play()


func play_click() -> void:
	play_sfx("click")


func play_music() -> void:
	if not is_instance_valid(_music_player) or _music_stream == null:
		return
	if _music_player.playing:
		return
	_music_player.stream = _music_stream
	_music_player.volume_db = _music_db()
	_music_player.play()


func set_music_volume(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	if is_instance_valid(_music_player):
		_music_player.volume_db = _music_db()


func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)


func set_music_paused(paused: bool) -> void:
	if is_instance_valid(_music_player):
		_music_player.stream_paused = paused


func _music_db() -> float:
	# Music sits behind the sound effects.
	return linear_to_db(maxf(0.0001, _music_volume * 0.5)) - 2.0


# ---------------------------------------------------------------------------
# Sound effect synthesis
# ---------------------------------------------------------------------------
func _build_sound_effects() -> void:
	_sfx_cache["click"] = _make_notes([
		{"freq": 1250.0, "start": 0.0, "dur": 0.05, "vol": 0.22},
	], "triangle")

	_sfx_cache["jump"] = _make_sweep(300.0, 760.0, 0.20, 0.34, "triangle")

	_sfx_cache["coin"] = _make_notes([
		{"freq": 987.8, "start": 0.00, "dur": 0.07, "vol": 0.22},
		{"freq": 1318.5, "start": 0.06, "dur": 0.20, "vol": 0.24},
	], "triangle")

	_sfx_cache["stomp"] = _make_sweep(210.0, 65.0, 0.16, 0.45, "square")

	_sfx_cache["hurt"] = _make_sweep(330.0, 80.0, 0.38, 0.36, "saw")

	_sfx_cache["win"] = _make_notes([
		{"freq": 523.3, "start": 0.00, "dur": 0.18, "vol": 0.24},
		{"freq": 659.3, "start": 0.13, "dur": 0.18, "vol": 0.24},
		{"freq": 784.0, "start": 0.26, "dur": 0.20, "vol": 0.25},
		{"freq": 1046.5, "start": 0.40, "dur": 0.42, "vol": 0.28},
	], "triangle")

	_sfx_cache["game_over"] = _make_notes([
		{"freq": 392.0, "start": 0.00, "dur": 0.26, "vol": 0.26},
		{"freq": 329.6, "start": 0.22, "dur": 0.26, "vol": 0.25},
		{"freq": 261.6, "start": 0.44, "dur": 0.55, "vol": 0.28},
	], "triangle")

	_sfx_cache["powerup"] = _make_notes([
		{"freq": 523.3, "start": 0.00, "dur": 0.09, "vol": 0.22},
		{"freq": 659.3, "start": 0.07, "dur": 0.09, "vol": 0.22},
		{"freq": 784.0, "start": 0.14, "dur": 0.09, "vol": 0.23},
		{"freq": 1046.5, "start": 0.21, "dur": 0.24, "vol": 0.26},
	], "triangle")

	_sfx_cache["shield"] = _make_notes([
		{"freq": 1568.0, "start": 0.00, "dur": 0.12, "vol": 0.14},
		{"freq": 2093.0, "start": 0.06, "dur": 0.18, "vol": 0.12},
		{"freq": 1318.5, "start": 0.14, "dur": 0.22, "vol": 0.13},
	], "sine")

	_sfx_cache["shard"] = _make_notes([
		{"freq": 880.0, "start": 0.00, "dur": 0.10, "vol": 0.20},
		{"freq": 1174.7, "start": 0.08, "dur": 0.10, "vol": 0.21},
		{"freq": 1568.0, "start": 0.16, "dur": 0.12, "vol": 0.22},
		{"freq": 2093.0, "start": 0.26, "dur": 0.34, "vol": 0.20},
	], "sine")

	_sfx_cache["treasure"] = _make_notes([
		{"freq": 659.3, "start": 0.00, "dur": 0.10, "vol": 0.24},
		{"freq": 784.0, "start": 0.09, "dur": 0.10, "vol": 0.24},
		{"freq": 1046.5, "start": 0.18, "dur": 0.13, "vol": 0.25},
		{"freq": 1318.5, "start": 0.29, "dur": 0.32, "vol": 0.27},
	], "triangle")

	_sfx_cache["break"] = _make_sweep(420.0, 60.0, 0.24, 0.42, "square")

	_sfx_cache["boss_hit"] = _make_notes([
		{"freq": 164.8, "start": 0.00, "dur": 0.16, "vol": 0.36},
		{"freq": 659.3, "start": 0.02, "dur": 0.08, "vol": 0.16},
		{"freq": 123.5, "start": 0.10, "dur": 0.20, "vol": 0.24},
	], "square")

	_sfx_cache["boss_defeat"] = _make_notes([
		{"freq": 523.3, "start": 0.00, "dur": 0.20, "vol": 0.26},
		{"freq": 392.0, "start": 0.16, "dur": 0.24, "vol": 0.26},
		{"freq": 261.6, "start": 0.36, "dur": 0.30, "vol": 0.27},
		{"freq": 130.8, "start": 0.60, "dur": 0.70, "vol": 0.30},
	], "saw")

	_sfx_cache["boss_shot"] = _make_sweep(760.0, 220.0, 0.18, 0.30, "square")

	_sfx_cache["hazard"] = _make_sweep(120.0, 48.0, 0.34, 0.28, "saw")

	_sfx_cache["achievement"] = _make_notes([
		{"freq": 784.0, "start": 0.00, "dur": 0.12, "vol": 0.22},
		{"freq": 1046.5, "start": 0.10, "dur": 0.12, "vol": 0.23},
		{"freq": 1318.5, "start": 0.20, "dur": 0.14, "vol": 0.24},
		{"freq": 1568.0, "start": 0.32, "dur": 0.40, "vol": 0.24},
	], "triangle")

	_sfx_cache["unlock"] = _make_notes([
		{"freq": 659.3, "start": 0.00, "dur": 0.10, "vol": 0.20},
		{"freq": 987.8, "start": 0.09, "dur": 0.12, "vol": 0.22},
		{"freq": 1318.5, "start": 0.20, "dur": 0.28, "vol": 0.24},
	], "sine")

	_sfx_cache["story"] = _make_notes([
		{"freq": 392.0, "start": 0.00, "dur": 0.24, "vol": 0.12},
		{"freq": 587.3, "start": 0.18, "dur": 0.32, "vol": 0.12},
	], "sine")


func _make_notes(notes: Array, wave: String) -> AudioStreamWAV:
	var end_time := 0.0
	for note in notes:
		end_time = maxf(end_time, float(note["start"]) + float(note["dur"]))
	var sample_count := int((end_time + 0.04) * RATE)
	var samples := PackedFloat32Array()
	samples.resize(sample_count)

	for i in sample_count:
		var t := float(i) / RATE
		var value := 0.0
		for note in notes:
			var start: float = note["start"]
			var duration: float = note["dur"]
			if t < start or t >= start + duration:
				continue
			var local := t - start
			var attack := minf(local / 0.008, 1.0)
			var release := pow(clampf(1.0 - local / duration, 0.0, 1.0), 1.6)
			var frequency: float = note["freq"]
			var phase := TAU * frequency * local
			value += _wave(phase, wave) * attack * release * float(note["vol"])
		samples[i] = value

	return _wav(samples)


func _make_sweep(freq_start: float, freq_end: float, duration: float, volume: float, wave: String) -> AudioStreamWAV:
	var sample_count := int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	var phase := 0.0

	for i in sample_count:
		var t := float(i) / sample_count
		var frequency := lerpf(freq_start, freq_end, t)
		phase += TAU * frequency / RATE
		var attack := minf(t / 0.02, 1.0)
		var release := pow(1.0 - t, 1.3)
		samples[i] = _wave(phase, wave) * attack * release * volume

	return _wav(samples)


func _wave(phase: float, shape: String) -> float:
	match shape:
		"triangle":
			return (2.0 / PI) * asin(sin(phase))
		"square":
			return 1.0 if sin(phase) >= 0.0 else -1.0
		"saw":
			return 2.0 * (phase / TAU - floor(phase / TAU + 0.5))
		_:
			return sin(phase)


# ---------------------------------------------------------------------------
# Music synthesis
# ---------------------------------------------------------------------------
func _build_music() -> AudioStreamWAV:
	# A friendly four-chord loop: C - Am - F - G, repeated twice.
	var melody := [
		72, 76, 79, 76, 77, 76, 72, 69,
		67, 72, 76, 72, 74, 72, 67, 71,
		72, 76, 79, 84, 81, 79, 76, 72,
		77, 79, 81, 79, 76, 72, 71, 67,
	]
	var bass_roots := [48, 45, 41, 43, 48, 45, 41, 43]
	var chords := [
		[48, 52, 55], [45, 48, 52], [41, 45, 48], [43, 47, 50],
		[48, 52, 55], [45, 48, 52], [41, 45, 48], [43, 47, 50],
	]

	var beat_count := melody.size()
	var duration := MUSIC_BEAT * beat_count
	var sample_count := int(duration * RATE)
	var samples := PackedFloat32Array()
	samples.resize(sample_count)

	for i in sample_count:
		var t := float(i) / RATE
		var beat_float := t / MUSIC_BEAT
		var beat_index := int(beat_float)
		var local_beat := t - float(beat_index) * MUSIC_BEAT
		var bar_index := int(t / (MUSIC_BEAT * 4.0)) % chords.size()

		# Lead melody with a soft pluck envelope.
		var midi: int = melody[beat_index % melody.size()]
		var lead_freq := _midi_to_freq(midi)
		var lead_env := exp(-local_beat * 4.2) * minf(local_beat * 80.0, 1.0)
		var lead := sin(TAU * lead_freq * local_beat) * lead_env * 0.115
		lead += sin(TAU * lead_freq * 2.0 * local_beat) * lead_env * 0.025

		# Warm bass pulse on every beat.
		var bass_freq := _midi_to_freq(bass_roots[bar_index])
		var bass_env := exp(-local_beat * 2.5)
		var bass := sin(TAU * bass_freq * t) * bass_env * 0.07

		# Long, quiet chord pad.
		var pad := 0.0
		for note in chords[bar_index]:
			var chord_freq := _midi_to_freq(int(note) + 12)
			pad += sin(TAU * chord_freq * t + sin(t * 0.7) * 0.2) * 0.016
		pad *= 0.72 + 0.28 * sin(t * 1.3)

		# Light foot-tap percussion.
		var tap := sin(TAU * 92.0 * local_beat) * exp(-local_beat * 22.0) * 0.035
		var tick := 0.0
		if local_beat > MUSIC_BEAT * 0.5 and local_beat < MUSIC_BEAT * 0.5 + 0.035:
			tick = (sin(TAU * 1800.0 * local_beat) * 0.012)

		var mixed := lead + bass + pad + tap + tick
		# Fade the loop edges to avoid pops.
		var fade := minf(minf(t / 0.08, 1.0), minf((duration - t) / 0.08, 1.0))
		samples[i] = mixed * fade * 0.82

	return _wav(samples, true)


func _midi_to_freq(note: int) -> float:
	return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)


func _wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var value := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream
