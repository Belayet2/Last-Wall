extends CanvasLayer
## In-game HUD, drawn over the world (light parchment panels):
##   top-left   = wall number, wall name and HP bar
##   top-middle = one helmet per enemy (it grays out when that enemy falls)
##   top-right  = coins
## Plus the wave intro title, the pause screen, the end-of-wave choice and the shop.

## Emitted when the player picks a button: "restart", "next" (start next wave), "shop".
signal action_chosen(action: String)

const GameData = preload("res://scripts/data/game_data.gd")
const FxData = preload("res://scripts/data/fx_data.gd")
const UI = preload("res://scripts/ui/ui_style.gd")
const ShopScript = preload("res://scripts/ui/shop.gd")

const MARGIN := 16.0

var ended := false

var _root: Control
var _coins := 0
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
var _intro_tip: Label
var _dim: ColorRect
var _msg_panel: PanelContainer
var _msg_title: Label
var _msg_sub: Label
var _msg_buttons: HBoxContainer
var _shop: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_wall_panel()
	_build_enemy_panel()
	_build_coin_panel()
	_build_intro()
	_build_message()


# ---------------------------------------------------------------- public

func setup_wall(number: int, title: String) -> void:
	_wall_number.text = "WALL %d" % number
	_wall_title.text = title


func set_wall_hp(hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_hp_label.text = "%d / %d" % [hp, max_hp]
	var ratio := float(hp) / float(max_hp)
	_hp_fill.bg_color = UI.HP_GOOD if ratio > 0.6 else (UI.HP_MID if ratio > 0.3 else UI.HP_LOW)


func set_coins(coins: int) -> void:
	var gained := coins > _coins
	_coins = coins
	_coins_label.text = str(coins)
	if gained:
		_coins_label.pivot_offset = _coins_label.size * 0.5
		_coins_label.scale = Vector2.ONE * FxData.COIN_PUNCH
		create_tween().tween_property(_coins_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## One icon per enemy, left to right (keys from art_data.gd).
func set_enemies(icon_keys: Array) -> void:
	for icon in _enemy_icons:
		icon.queue_free()
	_enemy_icons.clear()
	for key in icon_keys:
		var icon := UI.icon(key)
		_enemy_row.add_child(icon)
		_enemy_icons.append(icon)


func mark_enemy_down(i: int) -> void:
	if i < 0 or i >= _enemy_icons.size():
		return
	var icon := _enemy_icons[i]
	icon.modulate = Color(1, 1, 1, 0.3)
	icon.pivot_offset = icon.size * 0.5
	icon.scale = Vector2(1.5, 1.5)
	create_tween().tween_property(icon, "scale", Vector2.ONE, 0.2)


func show_intro(number: int, title: String, tip: String) -> void:
	_intro_title.text = "WALL %d" % number
	_intro_sub.text = title
	_intro_tip.text = tip
	_intro.modulate.a = 0.0
	_intro.visible = true
	var t := create_tween()
	t.tween_property(_intro, "modulate:a", 1.0, 0.25)
	t.tween_interval(GameData.INTRO_HOLD)
	t.tween_property(_intro, "modulate:a", 0.0, GameData.INTRO_FADE)
	t.tween_callback(_intro.hide)


## End-of-wave popup. `buttons` = [[text, action, primary], ...]
func show_end(title: String, subtitle: String, buttons: Array) -> void:
	ended = true
	_intro.hide()
	_show_message(title, subtitle, buttons)


func open_shop(continue_text: String) -> void:
	_msg_panel.visible = false
	_dim.visible = false
	_shop = ShopScript.new()
	_shop.setup(continue_text)
	_shop.continue_pressed.connect(func() -> void: action_chosen.emit("next"))
	_root.add_child(_shop)


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
		_show_message("Paused", "Press Esc to continue", [["Resume", "resume", true], ["Main Menu", "menu", false]])
	else:
		_dim.visible = false
		_msg_panel.visible = false


func _on_button(action: String) -> void:
	if action == "resume":
		_set_paused(false)
	else:
		action_chosen.emit(action)


func _show_message(title: String, subtitle: String, buttons: Array) -> void:
	_msg_title.text = title
	_msg_sub.text = subtitle
	for child in _msg_buttons.get_children():
		child.queue_free()
	var first: Button = null
	for spec in buttons:
		var b := UI.button(spec[0], spec[2])
		b.pressed.connect(_on_button.bind(spec[1]))
		_msg_buttons.add_child(b)
		if first == null:
			first = b
	_dim.visible = true
	_msg_panel.visible = true
	if first:
		first.grab_focus()


# ---------------------------------------------------------------- building

func _build_wall_panel() -> void:
	var panel := UI.panel()
	_root.add_child(panel)
	panel.position = Vector2(MARGIN, MARGIN)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	row.add_child(UI.icon("icon_wall"))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	var names := HBoxContainer.new()
	names.add_theme_constant_override("separation", 8)
	col.add_child(names)
	_wall_number = UI.label("WALL 1", 16, UI.ACCENT)
	names.add_child(_wall_number)
	_wall_title = UI.label("", 16)
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
	bg.bg_color = UI.HP_BG
	bg.border_color = UI.BORDER
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(5)
	_hp_fill = StyleBoxFlat.new()
	_hp_fill.bg_color = UI.HP_GOOD
	_hp_fill.set_corner_radius_all(5)
	_hp_bar.add_theme_stylebox_override("background", bg)
	_hp_bar.add_theme_stylebox_override("fill", _hp_fill)
	bar_row.add_child(_hp_bar)
	_hp_label = UI.label("0 / 0", 14, UI.INK_SOFT)
	_hp_label.custom_minimum_size = Vector2(72, 0)
	bar_row.add_child(_hp_label)


func _build_enemy_panel() -> void:
	var panel := UI.panel()
	_root.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP, true)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = MARGIN
	panel.offset_bottom = MARGIN
	_enemy_row = HBoxContainer.new()
	_enemy_row.add_theme_constant_override("separation", 6)
	panel.add_child(_enemy_row)


func _build_coin_panel() -> void:
	var panel := UI.panel()
	_root.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = -MARGIN
	panel.offset_right = -MARGIN
	panel.offset_top = MARGIN
	panel.offset_bottom = MARGIN
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(UI.icon("icon_coin"))
	_coins_label = UI.label("0", 24, UI.ACCENT)
	_coins_label.custom_minimum_size = Vector2(36, 0)
	row.add_child(_coins_label)


func _build_intro() -> void:
	_intro = VBoxContainer.new()
	_intro.position = Vector2(0, 240)
	_intro.size = Vector2(GameData.SCREEN_WIDTH, 200)
	_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro.add_theme_constant_override("separation", 2)
	_intro.visible = false
	_root.add_child(_intro)
	_intro_title = UI.centered(UI.world_label("", 64))
	_intro.add_child(_intro_title)
	_intro_sub = UI.centered(UI.world_label("", 26))
	_intro.add_child(_intro_sub)
	_intro_tip = UI.centered(UI.world_label("", 18))
	_intro.add_child(_intro_tip)


func _build_message() -> void:
	_dim = ColorRect.new()
	_dim.color = UI.DIM
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	_root.add_child(_dim)

	_msg_panel = UI.panel(28, 20)
	_msg_panel.visible = false
	_root.add_child(_msg_panel)
	_msg_panel.set_anchors_preset(Control.PRESET_CENTER, true)
	_msg_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_msg_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_msg_panel.offset_left = 0
	_msg_panel.offset_right = 0
	_msg_panel.offset_top = 0
	_msg_panel.offset_bottom = 0
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(460, 0)
	col.add_theme_constant_override("separation", 10)
	_msg_panel.add_child(col)
	_msg_title = UI.centered(UI.label("", 50, UI.ACCENT))
	col.add_child(_msg_title)
	_msg_sub = UI.centered(UI.label("", 20))
	_msg_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg_sub.custom_minimum_size = Vector2(460, 0)
	col.add_child(_msg_sub)
	col.add_child(UI.spacer(6))
	_msg_buttons = HBoxContainer.new()
	_msg_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_msg_buttons.add_theme_constant_override("separation", 16)
	col.add_child(_msg_buttons)
