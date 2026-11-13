extends Control
## Opening story: 3 screens in the throne room. Click / Space / Enter = next.
## "Skip story" jumps straight into the game.

const StoryData = preload("res://scripts/data/story_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const UI = preload("res://scripts/ui/ui_style.gd")

const BOX_TOP := 500.0
const PORTRAIT_X := 90.0

var _index := -1
var _speaker := ""
var _portrait: TextureRect
var _name_label: Label
var _text_label: Label
var _counter: Label
var _typing: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := TextureRect.new()
	bg.texture = ArtData.texture("story_throne_room")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	_portrait.size = ArtData.size_of("portrait_king")
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)

	var box := UI.panel(30, 18, true)
	box.position = Vector2(40, BOX_TOP)
	box.custom_minimum_size = Vector2(1200, 190)
	add_child(box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	box.add_child(col)
	_name_label = UI.label("", 26, UI.ACCENT)
	col.add_child(_name_label)
	_text_label = UI.label("", 28)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(1130, 80)
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_text_label)
	var bottom := HBoxContainer.new()
	col.add_child(bottom)
	_counter = UI.label("", 16, UI.INK_SOFT)
	_counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_counter)
	bottom.add_child(UI.label("Click or press Space to continue", 16, UI.INK_SOFT))

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
		if _typing and _typing.is_running():
			_typing.kill()
			_text_label.visible_ratio = 1.0
		else:
			_next()


func _next() -> void:
	_index += 1
	if _index >= StoryData.LINES.size():
		_start_game()
		return
	var line: Dictionary = StoryData.LINES[_index]
	_counter.text = "%d / %d" % [_index + 1, StoryData.LINES.size()]
	_name_label.text = line["speaker"]
	_text_label.text = line["text"]
	_text_label.visible_ratio = 0.0
	var text: String = line["text"]
	_typing = create_tween()
	_typing.tween_property(_text_label, "visible_ratio", 1.0, text.length() * StoryData.TYPE_TIME_PER_CHAR)

	if line["speaker"] != _speaker:
		_speaker = line["speaker"]
		_portrait.texture = ArtData.texture(line["portrait"])
		var left: bool = line["side"] == "left"
		var x := PORTRAIT_X if left else 1280.0 - PORTRAIT_X - _portrait.size.x
		var from := x - 80.0 if left else x + 80.0
		_portrait.position = Vector2(from, BOX_TOP - _portrait.size.y + 2)
		_portrait.modulate.a = 0.0
		var slide := create_tween().set_parallel(true)
		slide.tween_property(_portrait, "position:x", x, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		slide.tween_property(_portrait, "modulate:a", 1.0, 0.25)


func _start_game() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
