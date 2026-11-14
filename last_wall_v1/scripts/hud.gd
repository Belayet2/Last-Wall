extends CanvasLayer
## In-game HUD, drawn over the world (light parchment panels):
##   top-left   = wall number, wall name and the "last layer" bar (its weakest brick)
##   top-middle = one helmet per enemy (it grays out when that enemy falls)
##   top-right  = coins
## Plus the wave intro title, the pause screen, the end-of-wave choice, the shop and the build screen.

## Emitted when the player picks a button: "restart", "next" (go to the next wave), "shop",
## "build" (back to the build screen), "fight" (building done, start the wave), "menu".
signal action_chosen(action: String)

const GameData = preload("res://scripts/data/game_data.gd")
const FxData = preload("res://scripts/data/fx_data.gd")
const UI = preload("res://scripts/ui/ui_style.gd")
const ShopScript = preload("res://scripts/ui/shop.gd")
const BuildScript = preload("res://scripts/ui/build.gd")

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
var _build: Control
var _enemy_panel: PanelContainer
var _boss_bar: ProgressBar
var _banner: VBoxContainer
var _banner_title: Label
var _banner_sub: Label
var _banner_tween: Tween


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
	_build_banner()
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


## The shop. Its continue button sends `action` ("next" after a wave, "build" from the build screen).
func open_shop(continue_text: String, action: String = "next") -> void:
	_close_popups()
	_shop = ShopScript.new()
	_shop.setup(continue_text)
	_shop.continue_pressed.connect(func() -> void: action_chosen.emit(action))
	_add_popup(_shop)


## Before the fight: lay bricks on the wall.
func open_build(wall: Node2D, danger: Array, intro: String) -> void:
	_close_popups()
	_build = BuildScript.new()
	_build.setup(wall, danger, intro)
	_build.fight_pressed.connect(func() -> void:
		_close_popups()
		action_chosen.emit("fight"))
	_build.shop_pressed.connect(func() -> void: open_shop("Back to Building", "build"))
	_add_popup(_build)


## Popups go under the pause / message layer, so the pause menu is always on top.
func _add_popup(popup: Control) -> void:
	_root.add_child(popup)
	_root.move_child(popup, _dim.get_index())


func _close_popups() -> void:
	_msg_panel.visible = false
	_dim.visible = false
	for popup in [_shop, _build]:
		if is_instance_valid(popup):
			popup.queue_free()
	_shop = null
	_build = null


## Boss fight: the enemy panel becomes the boss's name and a big health bar.
func show_boss(boss_name: String, max_hp: int) -> void:
	_enemy_row.visible = false
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	_enemy_panel.add_child(col)
	col.add_child(UI.centered(UI.label(boss_name, 16, UI.ACCENT)))
	_boss_bar = ProgressBar.new()
	_boss_bar.custom_minimum_size = Vector2(380, 16)
	_boss_bar.show_percentage = false
	_boss_bar.max_value = max_hp
	_boss_bar.value = max_hp
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = UI.HP_BG
	bg.border_color = UI.BORDER
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UI.BOSS_BAR
	fill.set_corner_radius_all(5)
	_boss_bar.add_theme_stylebox_override("background", bg)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	col.add_child(_boss_bar)
	for notch in [0.33, 0.66]:                     # where the boss gets angrier
		var n := ColorRect.new()
		n.color = UI.INK
		n.size = Vector2(2, 16)
		n.position = Vector2(380 * notch, 0)
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_boss_bar.add_child(n)


func set_boss_hp(hp: int, _max_hp: int) -> void:
	if _boss_bar:
		create_tween().tween_property(_boss_bar, "value", float(hp), 0.2)


## Big announcement in the middle of the field (boss arrives, boss gets angry).
func show_banner(title: String, subtitle: String) -> void:
	_banner_title.text = title
	_banner_sub.text = subtitle
	_banner.visible = true
	_banner.modulate.a = 0.0
	_banner.scale = Vector2(1.3, 1.3)
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(1.8)
	_banner_tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.5)


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
	bar_row.add_child(UI.label("Last layer", 14, UI.INK_SOFT))
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(120, 14)
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
	_hp_label.custom_minimum_size = Vector2(60, 0)
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
	_enemy_panel = panel


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


func _build_banner() -> void:
	_banner = VBoxContainer.new()
	_banner.position = Vector2(0, 250)
	_banner.size = Vector2(GameData.SCREEN_WIDTH, 160)
	_banner.pivot_offset = Vector2(GameData.SCREEN_WIDTH * 0.5, 60)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	_root.add_child(_banner)
	_banner_title = UI.centered(UI.world_label("", 60))
	_banner_title.add_theme_color_override("font_color", UI.BANNER)
	_banner.add_child(_banner_title)
	_banner_sub = UI.centered(UI.world_label("", 24))
	_banner.add_child(_banner_sub)


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
