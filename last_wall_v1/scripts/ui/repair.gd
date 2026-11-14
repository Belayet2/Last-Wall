extends Control
## Before fighting on a retaken (fallen) wall: choose how much to repair it.
## It always gets a free patch; each step adds more HP and costs coins.

signal confirmed(steps: int)
signal shop_pressed

const UI = preload("res://scripts/ui/ui_style.gd")
const ShopData = preload("res://scripts/data/shop_data.gd")

var _steps := 0
var _bar: ProgressBar
var _base_mark: ColorRect
var _hp_label: Label
var _cost_label: Label
var _go: Button
var _minus: Button
var _plus: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = UI.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var number := GameState.current_wall
	var panel := UI.panel(30, 22)
	add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER, true)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 0
	panel.offset_bottom = 0
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(600, 0)
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var header := HBoxContainer.new()
	col.add_child(header)
	var title := UI.label("Repair %s" % GameState.wall_title(number), 34)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UI.icon("icon_coin"))
	var coins := UI.label(str(GameState.coins), 26, UI.ACCENT)
	coins.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(coins)
	var info := UI.label("The enemy left Wall %d in ruins. Your men patched it to %d%% for free. Pay coins to make it stronger before the fight." % [number, int(ShopData.FALLEN_WALL_FREE_HP * 100)], 16, UI.INK_SOFT)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(600, 0)
	col.add_child(info)

	# HP bar: the free patch, plus what you buy
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(600, 26)
	_bar.show_percentage = false
	_bar.max_value = GameState.wall_max_hp(number)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = UI.HP_BG
	bg.border_color = UI.BORDER
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UI.HP_GOOD
	fill.set_corner_radius_all(6)
	_bar.add_theme_stylebox_override("background", bg)
	_bar.add_theme_stylebox_override("fill", fill)
	col.add_child(_bar)
	_base_mark = ColorRect.new()
	_base_mark.color = UI.INK
	_base_mark.size = Vector2(2, 26)
	_base_mark.position = Vector2(600.0 * GameState.repair_base_hp() / GameState.wall_max_hp(number), 0)
	_bar.add_child(_base_mark)
	_hp_label = UI.centered(UI.label("", 22))
	col.add_child(_hp_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var none := UI.button("None", false, Vector2(90, 44), 18)
	none.pressed.connect(func() -> void: _set_steps(0))
	row.add_child(none)
	_minus = UI.button("-", false, Vector2(60, 44), 26)
	_minus.pressed.connect(func() -> void: _set_steps(_steps - 1))
	row.add_child(_minus)
	_cost_label = UI.centered(UI.label("", 20, UI.ACCENT))
	_cost_label.custom_minimum_size = Vector2(170, 0)
	_cost_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_cost_label)
	_plus = UI.button("+", false, Vector2(60, 44), 26)
	_plus.pressed.connect(func() -> void: _set_steps(_steps + 1))
	row.add_child(_plus)
	var most := UI.button("Max", false, Vector2(90, 44), 18)
	most.pressed.connect(func() -> void: _set_steps(GameState.repair_affordable_steps()))
	row.add_child(most)
	col.add_child(UI.centered(UI.label("Each step: +%d HP for %d coins" % [GameState.repair_step_hp(), GameState.repair_step_cost()], 15, UI.INK_SOFT)))

	col.add_child(UI.spacer(6))
	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 16)
	col.add_child(bottom)
	var shop := UI.button("Shop", false)
	shop.pressed.connect(func() -> void: shop_pressed.emit())
	bottom.add_child(shop)
	_go = UI.button("", true, Vector2(280, 50), 22)
	_go.pressed.connect(func() -> void: confirmed.emit(_steps))
	bottom.add_child(_go)
	_go.grab_focus()

	# start with as much repair as you can pay for, up to half the missing HP (you can change it)
	_set_steps(mini(GameState.repair_affordable_steps(), ceili(GameState.repair_max_steps() * 0.5)))


func _set_steps(steps: int) -> void:
	_steps = clampi(steps, 0, GameState.repair_affordable_steps())
	var number := GameState.current_wall
	var hp := GameState.repair_hp_for(_steps)
	var max_hp := GameState.wall_max_hp(number)
	create_tween().tween_property(_bar, "value", float(hp), 0.15)
	_hp_label.text = "Wall %d will start with %d / %d HP" % [number, hp, max_hp]
	var cost := GameState.repair_cost_for(_steps)
	_cost_label.text = "Cost: %d coins" % cost
	_minus.disabled = _steps <= 0
	_plus.disabled = _steps >= GameState.repair_affordable_steps()
	_go.text = "Repair & Fight" if _steps > 0 else "Fight as it is"
