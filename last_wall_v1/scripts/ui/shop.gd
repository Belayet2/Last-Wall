extends Control
## The shop (the game is paused while it is open).
## 4 upgrades, and a Continue button (it goes to the repair screen first if the next wall is in ruins).

signal continue_pressed

const ShopData = preload("res://scripts/data/shop_data.gd")
const UI = preload("res://scripts/ui/ui_style.gd")

var _continue_text := "Continue"
var _coins_label: Label
var _rows := {}            # key -> {"button": Button, "pips": Array[ColorRect]}


func setup(continue_text: String) -> void:
	_continue_text = continue_text


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = UI.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := UI.panel(28, 20)
	add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER, true)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 0
	panel.offset_bottom = 0
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(640, 0)
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var header := HBoxContainer.new()
	col.add_child(header)
	var title := UI.label("Armory", 40)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UI.icon("icon_coin"))
	_coins_label = UI.label("0", 28, UI.ACCENT)
	_coins_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_coins_label)
	col.add_child(UI.label("Spend coins on your shield. Upgrades last the whole game. (Wall repairs come next.)", 15, UI.INK_SOFT))
	col.add_child(UI.spacer(4))

	for key in ShopData.UPGRADES:
		_add_upgrade_row(col, key)

	col.add_child(UI.spacer(6))
	var go := UI.button(_continue_text, true, Vector2(260, 50), 24)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func() -> void: continue_pressed.emit())
	col.add_child(go)
	go.grab_focus()

	GameState.coins_changed.connect(_on_coins_changed)
	_refresh()


func _add_upgrade_row(col: VBoxContainer, key: String) -> void:
	var info: Dictionary = ShopData.UPGRADES[key]
	var row := _row_base(col, info["name"], info["desc"])
	var pips_box := HBoxContainer.new()
	pips_box.add_theme_constant_override("separation", 4)
	pips_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pips_box)
	var pips: Array[ColorRect] = []
	for i in range(GameState.upgrade_max_level(key)):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips_box.add_child(pip)
		pips.append(pip)
	var b := UI.button("", true, Vector2(130, 40), 18)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_on_buy.bind(key))
	row.add_child(b)
	_rows[key] = {"button": b, "pips": pips}


## A row: name + description on the left (the rest is added by the caller).
func _row_base(col: VBoxContainer, row_name: String, desc: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	text.add_child(UI.label(row_name, 20))
	var d := UI.label(desc, 14, UI.INK_SOFT)
	text.add_child(d)
	return row


func _on_buy(key: String) -> void:
	if GameState.buy_upgrade(key):
		GameState.audio.play("buy")
	_refresh()


func _on_coins_changed(_coins: int) -> void:
	_refresh()


func _refresh() -> void:
	_coins_label.text = str(GameState.coins)
	for key in _rows:
		var level: int = GameState.upgrade_levels[key]
		var pips: Array[ColorRect] = _rows[key]["pips"]
		for i in range(pips.size()):
			pips[i].color = UI.PIP_ON if i < level else UI.PIP_OFF
		var b: Button = _rows[key]["button"]
		var cost := GameState.upgrade_cost(key)
		if cost < 0:
			b.text = "MAX"
			b.disabled = true
		else:
			b.text = "%d coins" % cost
			b.disabled = GameState.coins < cost
