extends Node
## Plays sound effects and the music loop. Lives under the GameState autoload,
## so the music keeps playing between scenes. Use: GameState.audio.play("bounce")
## Press M to mute / unmute everything.

const AudioData = preload("res://scripts/data/audio_data.gd")

var _streams := {}           # name -> AudioStream
var _last_played := {}       # name -> time (seconds)
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # sounds and music keep going while paused
	for sound_name in AudioData.SOUNDS:
		var stream := _load(sound_name)
		if stream:
			_streams[sound_name] = stream
	for i in range(AudioData.VOICES):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_voices.append(p)
	_music = AudioStreamPlayer.new()
	_music.stream = _load(AudioData.MUSIC)
	_music.volume_db = AudioData.MUSIC_VOLUME_DB
	_music.finished.connect(_music.play)     # loop
	add_child(_music)


func play(sound_name: String) -> void:
	if not _streams.has(sound_name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound_name, -1.0)) < AudioData.SAME_SOUND_GAP:
		return
	_last_played[sound_name] = now
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = _streams[sound_name]
	p.volume_db = AudioData.SFX_VOLUME_DB + float(AudioData.SOUNDS[sound_name])
	p.pitch_scale = 1.0 + randf_range(-AudioData.PITCH_JITTER, AudioData.PITCH_JITTER)
	p.play()


## Starts the music (call it from a click: browsers only allow sound after one).
func start_music() -> void:
	if _music.stream and not _music.playing:
		_music.play()


## Quit the game cleanly: stop every sound first, then close a moment later
## (closing while a sound is still playing prints leak warnings).
func quit_game() -> void:
	_stop_all()
	await get_tree().create_timer(0.15, true, false, true).timeout
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


func _enter_tree() -> void:
	get_tree().set_auto_accept_quit(false)   # the window's X button goes through quit_game()


func _stop_all() -> void:
	for p in _voices:
		p.stop()
		p.stream = null
	_music.stop()
	_music.stream = null
	_streams.clear()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))


func _load(sound_name: String) -> AudioStream:
	for ext in AudioData.EXTENSIONS:
		var path: String = AudioData.FOLDER + sound_name + ext
		if ResourceLoader.exists(path):
			return load(path)
	push_warning("Missing sound: " + sound_name)
	return null
