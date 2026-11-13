extends SceneTree
## Synthesizes the placeholder sounds and the music loop into assets/audio/ (.wav).
## Run from the project folder:
##   godot --headless --path . --script res://tools/make_placeholder_audio.gd
## Existing files are NOT overwritten. Add "-- --force" to redo all, or "-- --only=bounce,coin".
## Your own sounds can be .ogg or .wav with the same name (an .ogg wins over a .wav).

const OUT := "res://assets/audio/"
const RATE := 22050

var rng := RandomNumberGenerator.new()
var force := false
var only: PackedStringArray = []


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--force":
			force = true
		elif arg.begins_with("--only="):
			only = arg.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(OUT)
	rng.seed = 42
	_save("bounce", _bounce)
	_save("wall_hit", _wall_hit)
	_save("wall_crack", _wall_crack)
	_save("enemy_hit", _enemy_hit)
	_save("enemy_down", _enemy_down)
	_save("coin", _coin)
	_save("throw", _throw)
	_save("tap", _tap)
	_save("click", _click)
	_save("buy", _buy)
	_save("horn", _horn)
	_save("wall_held", _wall_held)
	_save("wall_fell", _wall_fell)
	_save("victory", _victory)
	_save("defeat", _defeat)
	_save("music_loop", _music)
	quit()


func _save(file_name: String, maker: Callable) -> void:
	var path := OUT + file_name + ".wav"
	if not only.is_empty():
		if not only.has(file_name):
			return
	elif FileAccess.file_exists(path) and not force:
		print("skip (exists): ", path)
		return
	var samples: PackedFloat32Array = maker.call()
	var peak := 0.0
	for s in samples:
		peak = maxf(peak, absf(s))
	var gain := 0.9 / peak if peak > 0.9 else 1.0
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		bytes.encode_s16(i * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	wav.save_to_wav(path)
	print("wrote: ", path, "  (", snappedf(samples.size() / float(RATE), 0.01), " s)")


# ---------------------------------------------------------------- synth helpers

func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


func _midi(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


## Adds one note into `buf` starting at `start` seconds.
## wave: "sine", "square", "pulse", "tri", "saw". Frequency slides from f0 to f1.
func _note(buf: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, wave: String, vol: float, attack: float = 0.005, curve: float = 2.0) -> void:
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var phase := 0.0
	for i in range(n):
		var idx := i0 + i
		if idx >= buf.size():
			break
		var t := float(i) / n
		var f := lerpf(f0, f1, t)
		phase = fmod(phase + f / RATE, 1.0)
		var s := 0.0
		match wave:
			"sine":
				s = sin(phase * TAU)
			"square":
				s = 1.0 if phase < 0.5 else -1.0
			"pulse":
				s = 1.0 if phase < 0.25 else -1.0
			"tri":
				s = 4.0 * absf(phase - 0.5) - 1.0
			"saw":
				s = 2.0 * phase - 1.0
		var env := pow(1.0 - t, curve)
		var a := float(i) / (attack * RATE)
		if a < 1.0:
			env *= a
		buf[idx] += s * env * vol


## Filtered noise. `lowpass` 0..1 (small = darker). Cutoff can sweep from lp0 to lp1.
func _noise(buf: PackedFloat32Array, start: float, dur: float, vol: float, lp0: float, lp1: float, curve: float = 2.0) -> void:
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var y := 0.0
	for i in range(n):
		var idx := i0 + i
		if idx >= buf.size():
			break
		var t := float(i) / n
		y += lerpf(lp0, lp1, t) * (rng.randf_range(-1.0, 1.0) - y)
		buf[idx] += y * pow(1.0 - t, curve) * vol


# ---------------------------------------------------------------- sound effects

func _bounce() -> PackedFloat32Array:
	var b := _buf(0.3)
	_note(b, 0.0, 0.12, 880, 1320, "square", 0.25, 0.002, 3.0)
	_note(b, 0.0, 0.28, 1760, 1760, "sine", 0.3, 0.002, 2.5)
	_note(b, 0.02, 0.2, 2637, 2637, "sine", 0.12, 0.002, 3.0)
	return b


func _wall_hit() -> PackedFloat32Array:
	var b := _buf(0.35)
	_note(b, 0.0, 0.3, 140, 55, "sine", 0.8, 0.002, 2.0)
	_noise(b, 0.0, 0.18, 0.6, 0.25, 0.05)
	return b


func _wall_crack() -> PackedFloat32Array:
	var b := _buf(0.8)
	_note(b, 0.0, 0.6, 90, 40, "sine", 0.7, 0.002, 1.5)
	_noise(b, 0.0, 0.7, 0.7, 0.35, 0.04, 1.5)
	for i in range(14):
		_noise(b, rng.randf_range(0.0, 0.5), 0.03, 0.5, 0.6, 0.3)
	return b


func _enemy_hit() -> PackedFloat32Array:
	var b := _buf(0.12)
	_noise(b, 0.0, 0.07, 0.6, 0.7, 0.3)
	_note(b, 0.0, 0.1, 420, 200, "tri", 0.5, 0.002, 2.0)
	return b


func _enemy_down() -> PackedFloat32Array:
	var b := _buf(0.4)
	_note(b, 0.0, 0.32, 520, 130, "square", 0.22, 0.002, 1.5)
	_noise(b, 0.0, 0.25, 0.45, 0.4, 0.05)
	return b


func _coin() -> PackedFloat32Array:
	var b := _buf(0.3)
	_note(b, 0.0, 0.07, 988, 988, "square", 0.2, 0.002, 0.5)
	_note(b, 0.07, 0.22, 1319, 1319, "square", 0.2, 0.002, 2.0)
	return b


func _throw() -> PackedFloat32Array:
	var b := _buf(0.3)
	_noise(b, 0.0, 0.28, 0.5, 0.05, 0.35, 1.2)
	return b


func _tap() -> PackedFloat32Array:
	var b := _buf(0.06)
	_note(b, 0.0, 0.05, 300, 220, "tri", 0.5, 0.001, 2.0)
	_noise(b, 0.0, 0.03, 0.3, 0.5, 0.2)
	return b


func _click() -> PackedFloat32Array:
	var b := _buf(0.06)
	_note(b, 0.0, 0.05, 700, 620, "sine", 0.6, 0.001, 2.0)
	return b


func _buy() -> PackedFloat32Array:
	var b := _buf(0.4)
	var notes := [784.0, 988.0, 1319.0]
	for i in range(notes.size()):
		_note(b, i * 0.06, 0.2, notes[i], notes[i], "square", 0.18, 0.002, 2.0)
	return b


func _arpeggio(notes: Array, step: float, last: float, wave: String, vol: float) -> PackedFloat32Array:
	var b := _buf(step * (notes.size() - 1) + last + 0.05)
	for i in range(notes.size()):
		var d := last if i == notes.size() - 1 else step * 1.3
		_note(b, i * step, d, _midi(notes[i]), _midi(notes[i]), wave, vol, 0.005, 1.5)
		_note(b, i * step, d, _midi(notes[i] - 12), _midi(notes[i] - 12), "tri", vol * 0.6, 0.005, 1.5)
	return b


func _horn() -> PackedFloat32Array:
	return _arpeggio([67, 72], 0.22, 0.5, "saw", 0.18)


func _wall_held() -> PackedFloat32Array:
	return _arpeggio([72, 76, 79, 84], 0.1, 0.45, "square", 0.16)


func _wall_fell() -> PackedFloat32Array:
	return _arpeggio([67, 63, 60], 0.22, 0.6, "tri", 0.3)


func _victory() -> PackedFloat32Array:
	return _arpeggio([72, 76, 79, 84, 79, 84, 88], 0.13, 0.9, "square", 0.16)


func _defeat() -> PackedFloat32Array:
	return _arpeggio([64, 63, 62, 60], 0.35, 1.0, "tri", 0.3)


# ---------------------------------------------------------------- music (8 bars, loops)

func _music() -> PackedFloat32Array:
	var bpm := 112.0
	var eighth := 60.0 / bpm / 2.0
	# melody, one MIDI note per eighth (-1 = rest)
	var melody := [
		72, 76, 79, 76, 84, 79, 76, 79,
		81, 79, 76, 72, 76, -1, 74, 76,
		77, 81, 84, 81, 79, 77, 76, 74,
		74, 79, 83, 79, 74, -1, 79, -1,
		84, 83, 81, 79, 76, 79, 84, -1,
		81, 79, 77, 81, 84, 81, 77, 76,
		79, -1, 74, 79, 83, 81, 79, 74,
		76, 74, 72, 76, 72, -1, -1, -1,
	]
	var bass_roots := [48, 45, 41, 43, 48, 41, 43, 48]
	var b := _buf(eighth * melody.size())
	for i in range(melody.size()):
		var n: int = melody[i]
		if n > 0:
			_note(b, i * eighth, eighth * 0.95, _midi(n), _midi(n), "pulse", 0.11, 0.004, 1.2)
	for bar in range(8):
		var root: int = bass_roots[bar]
		var pattern := [root, root, root + 7, root]
		for beat in range(4):
			var start := (bar * 8 + beat * 2) * eighth
			var bn: float = pattern[beat]
			_note(b, start, eighth * 1.9, _midi(bn), _midi(bn), "tri", 0.22, 0.004, 1.0)
			if beat % 2 == 0:
				_note(b, start, 0.12, 120, 45, "sine", 0.35, 0.001, 2.0)   # kick
			_noise(b, start + eighth, 0.03, 0.06, 0.9, 0.9)               # hi-hat on the off-beat
	return b
