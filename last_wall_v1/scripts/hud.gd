extends CanvasLayer
## In-game HUD, drawn over the world (no side panels):
##   top-left   = wall number, wall name and HP bar
##   top-middle = one helmet per enemy (it grays out when that enemy falls)
##   top-right  = coins
## Plus the wave intro title, the pause screen and the end message.

signal restart_requested

const ArtData = preload("res://scripts/data/art_data.gd")
const GameData = preload("res://scripts/data/game_data.gd")

const TEXT := Color8(244, 236, 220)
const TEXT_DIM := Color8(206, 196, 176)
const GOLD := Color8(250, 210, 90)
const INK := Color8(20, 16, 18)
const PANEL_BG := Color(0.07, 0.06, 0.08, 0.78)
const PANEL_BORDER := Color8(196, 156, 78)
const HP_GOOD := Color8(96, 196, 92)
const HP_MID := Color8(232, 172, 60)
const HP_LOW := Color8(224, 72, 60)
const MARGIN := 16.0

var ended := false

var _wall_number: Label
var _wall_title: Label
var _hp_bar: ProgressBar
var _hp_fill: StyleBoxFlat
var _hp_label: Label
var _coins_label: Label
var _enemy_row: HBoxContainer
var _enemy_icons: Array[TextureRect] = []
var _intro: VBoxContainer
var _intro_title: Label
var _intro_sub: Label
var _dim: ColorRect
var _msg_panel: PanelContainer
var _msg_title: Label
var _msg_sub: Label
var _msg_button: Button
var _button_action := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_wall_panel(root)
	_build_enemy_panel(root)
	_build_coin_panel(root)
	_build_intro(root)
	_build_message(root)


# ---------------------------------------------------------------- public

func setup_wall(number: int, title: String) -> void:
	_wall_number.text = "WALL %d" % number
	_wall_title.text = title


func set_wall_hp(hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_hp_label.text = "%d / %d" % [hp, max_hp]
	var ratio := float(hp) / float(max_hp)
	_hp_fill.bg_color = HP_GOOD if ratio > 0.6 else (HP_MID if ratio > 0.3 else HP_LOW)


func set_coins(coins: int) -> void:
	_coins_label.text = str(coins)


func set_enemy_count(count: int) -> void:
	for icon in _enemy_icons:
		icon.queue_free()
	_enemy_icons.clear()
	for i in range(count):
		var icon := _icon("icon_enemy")
		_enemy_row.add_child(icon)
		_enemy_icons.append(icon)


func mark_enemy_down(i: int) -> void:
	if i < 0 or i >= _enemy_icons.size():
		return
	var icon := _enemy_icons[i]
	icon.modulate = Color(0.35, 0.35, 0.35, 0.55)
	icon.pivot_offset = icon.size * 0.5
	icon.scale = Vector2(1.5, 1.5)
	create_tween().tween_property(icon, "scale", Vector2.ONE, 0.2)


func show_intro(number: int, title: String) -> void:
	_intro_title.text = "WALL %d" % number
	_intro_sub.text = title
	_intro.modulate.a = 0.0
	_intro.visible = true
	var t := create_tween()
	t.tween_property(_intro, "modulate:a", 1.0, 0.25)
	t.tween_interval(GameData.INTRO_HOLD)
	t.tween_property(_intro, "modulate:a", 0.0, GameData.INTRO_FADE)
	t.tween_callback(_intro.hide)


func show_end(title: String, subtitle: String, button_text: String) -> void:
	ended = true
	_intro.hide()
	_show_message(title, subtitle, button_text, "restart")


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if ended:
		return
	if event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	if paused:
		_show_message("Paused", "Press Esc to continue", "Resume", "resume")
	else:
		_dim.visible = false
		_msg_panel.visible = false


func _on_button_pressed() -> void:
	if _button_action == "restart":
		restart_requested.emit()
	elif _button_action == "resume":
		_set_paused(false)


func _show_message(title: String, subtitle: String, button_text: String, action: String) -> void:
	_msg_title.text = title
	_msg_sub.text = subtitle
	_msg_button.text = button_text
	_button_action = action
	_dim.visible = true
	_msg_panel.visible = true
	_msg_button.grab_focus()


# ---------------------------------------------------------------- building

func _build_wall_panel(root: Control) -> void:
	var panel := _panel()
	root.add_child(panel)
	panel.position = Vector2(MARGIN, MARGIN)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	row.add_child(_icon("icon_wall"))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	var names := HBoxContainer.new()
	names.add_theme_constant_override("separation", 8)
	col.add_child(names)
	_wall_number = _label("WALL 1", 16, GOLD)
	names.add_child(_wall_number)
	_wall_title = _label("", 16, TEXT)
	names.add_child(_wall_title)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 8)
	col.add_child(bar_row)
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(170, 14)
	_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hp_bar.show_percentage = false
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color8(28, 24, 28)
	bg.border_color = Color8(10, 8, 10)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(5)
	_hp_fill = StyleBoxFlat.new()
	_hp_fill.bg_color = HP_GOOD
	_hp_fill.set_corner_radius_all(5)
	_hp_bar.add_theme_stylebox_override("background", bg)
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill)
	bar_row.add_child(_hp_bar)
	_hp_label = _label("0 / 0", 14, TEXT_DIM)
	_hp_label.custom_minimum_size = Vector2(72, 0)
	bar_row.add_child(_hp_label)


func _build_enemy_panel(root: Control) -> void:
	var panel := _panel()
	root.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP, true)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = MARGIN
	panel.offset_bottom = MARGIN
	_enemy_row = HBoxContainer.new()
	_enemy_row.add_theme_constant_override("separation", 6)
	panel.add_child(_enemy_row)


func _build_coin_panel(root: Control) -> void:
	var panel := _panel()
	root.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = -MARGIN
	panel.offset_right = -MARGIN
	panel.offset_top = MARGIN
	panel.offset_bottom = MARGIN
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(_icon("icon_coin"))
	_coins_label = _label("0", 24, GOLD)
	_coins_label.custom_minimum_size = Vector2(36, 0)
	row.add_child(_coins_label)


func _build_intro(root: Control) -> void:
	_intro = VBoxContainer.new()
	_intro.position = Vector2(0, 240)
	_intro.size = Vector2(GameData.SCREEN_WIDTH, 200)
	_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro.add_theme_constant_override("separation", 2)
	_intro.visible = false
	root.add_child(_intro)
	_intro_title = _centered(_label("", 64, GOLD))
	_intro.add_child(_intro_title)
	_intro_sub = _centered(_label("", 26, TEXT))
	_intro.add_child(_intro_sub)
	var hint := _centered(_label("Move with A / D or the arrow keys.  Stand on the red marks to block.", 18, TEXT_DIM))
	_intro.add_child(hint)


func _build_message(root: Control) -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	root.add_child(_dim)

	_msg_panel = _panel(28, 20)
	_msg_panel.visible = false
	root.add_child(_msg_panel)
	_msg_panel.set_anchors_preset(Control.PRESET_CENTER, true)
	_msg_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_msg_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_msg_panel.offset_left = 0
	_msg_panel.offset_right = 0
	_msg_panel.offset_top = 0
	_msg_panel.offset_bottom = 0
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(420, 0)
	col.add_theme_constant_override("separation", 10)
	_msg_panel.add_child(col)
	_msg_title = _centered(_label("", 52, GOLD))
	col.add_child(_msg_title)
	_msg_sub = _centered(_label("", 20, TEXT))
	col.add_child(_msg_sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap)
	_msg_button = _button()
	_msg_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_msg_button.pressed.connect(_on_button_pressed)
	col.add_child(_msg_button)


# ---------------------------------------------------------------- small helpers

func _panel(h_margin: float = 14.0, v_margin: float = 8.0) -> PanelContainer:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = PANEL_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = h_margin
	sb.content_margin_right = h_margin
	sb.content_margin_top = v_margin
	sb.content_margin_bottom = v_margin
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _centered(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _icon(key: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = ArtData.texture(key)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = ArtData.size_of(key)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _button() -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(200, 46)
	b.add_theme_font_size_override("font_size", 22)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, INK)
	var looks := {"normal": GOLD, "hover": GOLD.lightened(0.18), "pressed": GOLD.darkened(0.18)}
	for state in looks:
		var sb := StyleBoxFlat.new()
		sb.bg_color = looks[state]
		sb.border_color = INK
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		b.add_theme_stylebox_override(state, sb)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = TEXT
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(8)
	focus.expand_margin_left = 3
	focus.expand_margin_right = 3
	focus.expand_margin_top = 3
	focus.expand_margin_bottom = 3
	b.add_theme_stylebox_override("focus", focus)
	return b
