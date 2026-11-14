extends Node
## Plays sound effects and the narrator's voice. Lives under the GameState autoload,
## so a voice line keeps playing between scenes. Use: GameState.audio.play("bounce")
## Press M to mute / unmute everything. (There is no background music.)

signal voice_finished

const AudioData = preload("res://scripts/data/audio_data.gd")

var _streams := {}           # name -> AudioStream
var _last_played := {}       # name -> time (seconds)
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _voice: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # sounds keep going while paused
	for sound_name in AudioData.SOUNDS:
		var stream := _find(AudioData.FOLDER, sound_name)
		if stream:
			_streams[sound_name] = stream
		else:
			push_warning("Missing sound: " + sound_name)
	for i in range(AudioData.VOICES):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_voice = AudioStreamPlayer.new()
	_voice.volume_db = AudioData.VOICE_VOLUME_DB
	_voice.finished.connect(func() -> void: voice_finished.emit())
	add_child(_voice)


func play(sound_name: String) -> void:
	if not _streams.has(sound_name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound_name, -1.0)) < AudioData.SAME_SOUND_GAP:
		return
	_last_played[sound_name] = now
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = _streams[sound_name]
	p.volume_db = AudioData.SFX_VOLUME_DB + float(AudioData.SOUNDS[sound_name])
	p.pitch_scale = 1.0 + randf_range(-AudioData.PITCH_JITTER, AudioData.PITCH_JITTER)
	p.play()


## Plays a narrator line from assets/audio/voice/ (e.g. "narration_01").
## Returns false if that recording does not exist yet (the game then just shows the text).
func play_voice(line_name: String) -> bool:
	stop_voice()
	var stream := _find(AudioData.VOICE_FOLDER, line_name)
	if stream == null:
		return false
	_voice.stream = stream
	_voice.play()
	return true


func stop_voice() -> void:
	_voice.stop()


func is_voice_playing() -> bool:
	return _voice.playing


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
	for p in _players:
		p.stop()
		p.stream = null
	_voice.stop()
	_voice.stream = null
	_streams.clear()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))


func _find(folder: String, file_name: String) -> AudioStream:
	for ext in AudioData.EXTENSIONS:
		var path: String = folder + file_name + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null
