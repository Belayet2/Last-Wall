extends CanvasLayer
## Small HUD on the side panels: wall HP, coins, enemies left, and the end message.

signal restart_requested

const GameData = preload("res://scripts/data/game_data.gd")

const TEXT := Color8(240, 230, 210)
const GOLD := Color8(250, 210, 90)
const HP_GOOD := Color8(90, 190, 90)
const HP_MID := Color8(230, 170, 60)
const HP_LOW := Color8(220, 70, 60)

var ended := false

var _wall_name: Label
var _hp_bar: ProgressBar
var _hp_fill: StyleBoxFlat
var _hp_label: Label
var _coins_label: Label
var _enemies_label: Label
var _msg_box: ColorRect
var _msg_title: Label
var _msg_sub: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10

	var left := VBoxContainer.new()
	left.position = Vector2(24, 24)
	left.custom_minimum_size = Vector2(GameData.FIELD_LEFT - 48, 0)
	left.add_theme_constant_override("separation", 8)
	add_child(left)
	left.add_child(_label("LAST WALL", 34, GOLD))
	_wall_name = _label("Wall 1", 18, TEXT)
	_wall_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	left.add_child(_wall_name)
	left.add_child(_spacer(16))
	left.add_child(_label("Wall HP", 20, TEXT))
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(GameData.FIELD_LEFT - 48, 24)
	_hp_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color8(25, 22, 26)
	bg.set_corner_radius_all(4)
	_hp_fill = StyleBoxFlat.new()
	_hp_fill.bg_color = HP_GOOD
	_hp_fill.set_corner_radius_all(4)
	_hp_bar.add_theme_stylebox_override("background", bg)
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill)
	left.add_child(_hp_bar)
	_hp_label = _label("300 / 300", 18, TEXT)
	left.add_child(_hp_label)

	var right := VBoxContainer.new()
	right.position = Vector2(GameData.FIELD_RIGHT + 24, 24)
	right.custom_minimum_size = Vector2(1280 - GameData.FIELD_RIGHT - 48, 0)
	right.add_theme_constant_override("separation", 8)
	add_child(right)
	right.add_child(_label("Coins", 20, TEXT))
	_coins_label = _label("0", 34, GOLD)
	right.add_child(_coins_label)
	right.add_child(_spacer(16))
	right.add_child(_label("Enemies left", 20, TEXT))
	_enemies_label = _label("0", 34, TEXT)
	right.add_child(_enemies_label)
	right.add_child(_spacer(40))
	var help := _label("A / D  or  Left / Right\nto move\n\nEsc to pause", 16, Color(TEXT, 0.7))
	right.add_child(help)

	_msg_box = ColorRect.new()
	_msg_box.color = Color(0, 0, 0, 0.6)
	_msg_box.position = Vector2(GameData.FIELD_LEFT, 250)
	_msg_box.size = Vector2(GameData.FIELD_RIGHT - GameData.FIELD_LEFT, 170)
	_msg_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_msg_box.visible = false
	add_child(_msg_box)
	_msg_title = _label("", 60, GOLD)
	_msg_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_title.position = Vector2(0, 22)
	_msg_title.size = Vector2(_msg_box.size.x, 80)
	_msg_box.add_child(_msg_title)
	_msg_sub = _label("", 22, TEXT)
	_msg_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_sub.position = Vector2(0, 110)
	_msg_sub.size = Vector2(_msg_box.size.x, 40)
	_msg_box.add_child(_msg_sub)


func set_wall_name(text: String) -> void:
	_wall_name.text = text


func set_wall_hp(hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_hp_label.text = "%d / %d" % [hp, max_hp]
	var ratio := float(hp) / float(max_hp)
	_hp_fill.bg_color = HP_GOOD if ratio > 0.6 else (HP_MID if ratio > 0.3 else HP_LOW)


func set_coins(coins: int) -> void:
	_coins_label.text = str(coins)


func set_enemies(count: int) -> void:
	_enemies_label.text = str(count)


func show_end(title: String, subtitle: String) -> void:
	ended = true
	_show_message(title, subtitle)


func _show_message(title: String, subtitle: String) -> void:
	_msg_title.text = title
	_msg_sub.text = subtitle
	_msg_box.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if ended:
		var mouse := event as InputEventMouseButton
		var clicked := mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
		if clicked or event.is_action_pressed("ui_accept"):
			restart_requested.emit()
		return
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		if get_tree().paused:
			_show_message("Paused", "Press Esc to continue")
		else:
			_msg_box.visible = false


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color8(20, 16, 18))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
