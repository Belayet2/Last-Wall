extends Control
## The opening story: a slideshow of pictures, told in text by a narrator.
## The text types out, then waits: click / Space / Enter = show all text, then next picture.
## "Skip story" jumps straight into the game.

const StoryData = preload("res://scripts/data/story_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const UI = preload("res://scripts/ui/ui_style.gd")

const BOX_WIDTH := 1100.0
const BOX_BOTTOM_GAP := 22.0

var _index := -1
var _pictures: Array[TextureRect] = []
var _front := 0
var _box: PanelContainer
var _text: Label
var _hint: Label
var _dots: Array[ColorRect] = []
var _typing: Tween
var _zoom: Tween
var _hint_pulse: Tween
var _leaving := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var black := ColorRect.new()
	black.color = Color(0.1, 0.09, 0.11)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	for i in range(2):                       # two pictures that crossfade
		var pic := TextureRect.new()
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_SCALE
		pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pic.pivot_offset = Vector2(640, 360)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.modulate.a = 0.0
		add_child(pic)
		_pictures.append(pic)

	# soft shadow at the bottom so the text box stands out from any picture
	var shade := TextureRect.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.45)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	shade.texture = gt
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.position = Vector2(0, 420)
	shade.size = Vector2(1280, 300)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	# the text box: solid parchment, big dark text, grows upward from the bottom
	_box = UI.panel(34, 20, true)
	_box.custom_minimum_size = Vector2(BOX_WIDTH, 0)
	add_child(_box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_box.add_child(col)
	_text = UI.label("", StoryData.TEXT_SIZE)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(BOX_WIDTH - 68, 0)
	_text.add_theme_constant_override("line_spacing", 6)
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING   # box keeps its size while typing
	col.add_child(_text)
	var bottom := HBoxContainer.new()
	col.add_child(bottom)
	var dots := HBoxContainer.new()
	dots.add_theme_constant_override("separation", 6)
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(dots)
	for i in range(StoryData.SLIDES.size()):
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(12, 12)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots.add_child(d)
		_dots.append(d)
	_hint = UI.label("Click or press Space to continue  >", 18, UI.ACCENT)
	bottom.add_child(_hint)

	var skip := UI.button("Skip story", false, Vector2(160, 42), 18)
	skip.focus_mode = Control.FOCUS_NONE     # so Space never presses it by accident
	skip.position = Vector2(1280 - 160 - 24, 24)
	skip.pressed.connect(_start_game)
	add_child(skip)

	_next()


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	var clicked := mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	if clicked or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		GameState.audio.play("click")
		if _typing and _typing.is_running():
			_typing.kill()                   # first click: show the whole text
			_text.visible_ratio = 1.0
			_show_hint()
		else:
			_next()


func _next() -> void:
	if _leaving:
		return
	_index += 1
	if _index >= StoryData.SLIDES.size():
		_start_game()
		return
	var slide: Dictionary = StoryData.SLIDES[_index]
	for i in range(_dots.size()):
		_dots[i].color = UI.PIP_ON if i <= _index else UI.PIP_OFF

	# crossfade to the new picture, which slowly zooms in
	var old := _pictures[_front]
	_front = 1 - _front
	var pic := _pictures[_front]
	pic.texture = ArtData.texture(slide["image"])
	pic.scale = Vector2.ONE
	move_child(pic, old.get_index())         # new picture goes under the old one, then the old fades out
	pic.modulate.a = 1.0
	create_tween().tween_property(old, "modulate:a", 0.0, StoryData.FADE_TIME)
	if _zoom:
		_zoom.kill()
	_zoom = create_tween()
	_zoom.tween_property(pic, "scale", Vector2.ONE * StoryData.ZOOM, 14.0)

	# the text types out, then the "continue" hint appears
	var text: String = slide["text"]
	_text.text = text
	_text.visible_ratio = 0.0
	_place_box()
	call_deferred("_place_box")
	_hint.modulate.a = 0.0
	if _hint_pulse:
		_hint_pulse.kill()
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, text.length() / StoryData.TYPE_CHARS_PER_SECOND)
	_typing.tween_callback(_show_hint)


## Keeps the box centered at the bottom; it grows upward for longer text.
func _place_box() -> void:
	_box.reset_size()
	var h := _box.get_combined_minimum_size().y
	_box.position = Vector2((1280.0 - BOX_WIDTH) * 0.5, 720.0 - BOX_BOTTOM_GAP - h)


func _show_hint() -> void:
	if _hint_pulse:
		_hint_pulse.kill()
	_hint.modulate.a = 1.0
	_hint_pulse = create_tween().set_loops()
	_hint_pulse.tween_property(_hint, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE)
	_hint_pulse.tween_property(_hint, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)


func _start_game() -> void:
	if _leaving:
		return
	_leaving = true
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
