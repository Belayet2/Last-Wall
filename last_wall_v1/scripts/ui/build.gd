extends Control
## Before every fight: lay your bricks on the wall.
## Pick a brick type, click a column on the wall to lay it on top, right-click to take the top brick off.
## The wall itself handles the clicks (wall.gd); this panel picks the brick and has the buttons.

signal fight_pressed
signal shop_pressed

const UI = preload("res://scripts/ui/ui_style.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const BrickData = preload("res://scripts/data/brick_data.gd")

const PANEL_Y := 168.0

var _wall: Node2D
var _danger: Array = []
var _intro := ""
var _type_buttons := {}       # type -> Button
var _coins_label: Label
var _stock_label: Label


func setup(wall: Node2D, danger: Array, intro: String) -> void:
	_wall = wall
	_danger = danger
	_intro = intro


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE      # clicks outside the panel go to the wall

	var panel := UI.panel(24, 16, true)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(700, 0)
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	col.add_child(header)
	var title := UI.label("Build Wall %d: %s" % [GameState.current_wall, GameState.wall_title(GameState.current_wall)], 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UI.icon("icon_coin"))
	_coins_label = UI.label("0", 24, UI.ACCENT)
	_coins_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_coins_label)

	var info := UI.label(_intro, 16, UI.INK_SOFT)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(700, 0)
	col.add_child(info)
	var how := UI.label("Click or drag across the wall to lay bricks (one per column per drag).  Right-click or right-drag takes them off.  Red strips = where the enemies aim.", 15, UI.INK)
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.custom_minimum_size = Vector2(700, 0)
	col.add_child(how)

	var types := HBoxContainer.new()
	types.alignment = BoxContainer.ALIGNMENT_CENTER
	types.add_theme_constant_override("separation", 10)
	col.add_child(types)
	for i in range(BrickData.ORDER.size()):
		var key: String = BrickData.ORDER[i]
		var b := UI.button("", false, Vector2(166, 84), 15)
		b.icon = ArtData.texture(BrickData.TYPES[key]["art"])
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.tooltip_text = "%s (key %d)" % [BrickData.TYPES[key]["desc"], i + 1]
		b.pressed.connect(_select.bind(key))
		types.add_child(b)
		_type_buttons[key] = b
	_stock_label = UI.centered(UI.label("", 15, UI.INK_SOFT))
	col.add_child(_stock_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	col.add_child(buttons)
	var shop := UI.button("Shop", false, Vector2(130, 46))
	shop.pressed.connect(func() -> void: shop_pressed.emit())
	buttons.add_child(shop)
	var auto := UI.button("Auto-build", false, Vector2(150, 46))
	auto.tooltip_text = "Lays all your bricks for you, most where the enemies aim"
	auto.pressed.connect(_auto_build)
	buttons.add_child(auto)
	var clear := UI.button("Clear", false, Vector2(110, 46))
	clear.tooltip_text = "Takes every brick you laid back off the wall"
	clear.pressed.connect(_clear)
	buttons.add_child(clear)
	var fight := UI.button("Fight!", true, Vector2(170, 46), 24)
	fight.pressed.connect(func() -> void: fight_pressed.emit())
	buttons.add_child(fight)
	for b in buttons.get_children():
		(b as Button).focus_mode = Control.FOCUS_NONE   # Space / Enter never press them by accident

	panel.reset_size()
	panel.position = Vector2((1280.0 - panel.get_combined_minimum_size().x) * 0.5, PANEL_Y)

	GameState.bricks_changed.connect(_refresh)
	GameState.coins_changed.connect(_on_coins_changed)
	_wall.layout_changed.connect(_refresh)
	_wall.build_mode = true
	_wall.set_danger(_danger)
	_select(_best_type())


func _exit_tree() -> void:
	if is_instance_valid(_wall):
		_wall.build_mode = false


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		var n := key.keycode - KEY_1
		if n >= 0 and n < BrickData.ORDER.size():
			_select(BrickData.ORDER[n])
			get_viewport().set_input_as_handled()


func _select(type_key: String) -> void:
	_wall.select_type(type_key)
	_refresh()


## The type you have the most of (so a click does something right away).
func _best_type() -> String:
	var best: String = BrickData.ORDER[1]
	for key in BrickData.ORDER:
		if GameState.brick_count(key) > GameState.brick_count(best):
			best = key
	return best


func _refresh() -> void:
	_coins_label.text = str(GameState.coins)
	for key in _type_buttons:
		var info: Dictionary = BrickData.TYPES[key]
		var b: Button = _type_buttons[key]
		b.text = "%s\nHP %d     x%d" % [info["name"], info["hp"], GameState.brick_count(key)]
		var on: bool = _wall.selected_type == key
		for state in ["normal", "hover", "pressed"]:
			var sb: StyleBoxFlat = b.get_theme_stylebox(state).duplicate()
			sb.bg_color = UI.BUTTON if on else UI.BUTTON_ALT
			if state == "hover":
				sb.bg_color = sb.bg_color.lightened(0.15)
			sb.set_border_width_all(3 if on else 2)
			b.add_theme_stylebox_override(state, sb)
		b.modulate = Color(1, 1, 1, 1.0 if GameState.brick_count(key) > 0 else 0.55)
	var left := GameState.total_bricks()
	if left == 0:
		_stock_label.text = "No bricks left. Buy more in the Shop, or Fight!"
	else:
		_stock_label.text = "Bricks left to lay: %d" % left


func _on_coins_changed(_coins: int) -> void:
	_refresh()


## Lays every brick you have: strongest bricks first, on the columns that need them most.
func _auto_build() -> void:
	while true:
		var type_key := ""
		for i in range(BrickData.ORDER.size() - 1, -1, -1):
			if GameState.brick_count(BrickData.ORDER[i]) > 0:
				type_key = BrickData.ORDER[i]
				break
		if type_key == "":
			return
		var best := -1
		var best_score := INF
		for col in range(BrickData.COLUMNS):
			if _wall.is_full(col):
				continue
			var danger: float = _danger[col] if col < _danger.size() else 0.5
			var score := float(_wall.column_hp(col)) / (0.35 + danger)
			if score < best_score:
				best_score = score
				best = col
		if best < 0 or not _wall.place(best, type_key):
			return


func _clear() -> void:
	for col in range(BrickData.COLUMNS):
		while _wall.take_off(col):
			pass
