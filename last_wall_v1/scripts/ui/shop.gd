extends Control
## The shop (the game is paused while it is open).
## Left: bricks for your wall (you lay them on the build screen). Right: shield upgrades.

signal continue_pressed

const ShopData = preload("res://scripts/data/shop_data.gd")
const BrickData = preload("res://scripts/data/brick_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const UI = preload("res://scripts/ui/ui_style.gd")

var _continue_text := "Continue"
var _coins_label: Label
var _rows := {}            # upgrade key -> {"button": Button, "pips": Array[ColorRect]}
var _brick_rows := {}      # brick type -> {"one": Button, "many": Button, "have": Label}


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

	var panel := UI.panel(28, 20, true)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)

	var header := HBoxContainer.new()
	col.add_child(header)
	var title := UI.label("Shop", 40)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(UI.icon("icon_coin"))
	_coins_label = UI.label("0", 28, UI.ACCENT)
	_coins_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_coins_label)

	var halves := HBoxContainer.new()
	halves.add_theme_constant_override("separation", 36)
	col.add_child(halves)

	var bricks := VBoxContainer.new()
	bricks.custom_minimum_size = Vector2(560, 0)
	bricks.add_theme_constant_override("separation", 8)
	halves.add_child(bricks)
	bricks.add_child(UI.label("Bricks", 26, UI.ACCENT))
	bricks.add_child(UI.label("Lay them on the wall before the fight. Unused bricks are kept.", 14, UI.INK_SOFT))
	for key in BrickData.ORDER:
		_add_brick_row(bricks, key)

	var line := ColorRect.new()
	line.color = Color(UI.BORDER, 0.5)
	line.custom_minimum_size = Vector2(2, 0)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halves.add_child(line)

	var upgrades := VBoxContainer.new()
	upgrades.custom_minimum_size = Vector2(430, 0)
	upgrades.add_theme_constant_override("separation", 8)
	halves.add_child(upgrades)
	upgrades.add_child(UI.label("Shield", 26, UI.ACCENT))
	upgrades.add_child(UI.label("Upgrades last the whole game.", 14, UI.INK_SOFT))
	for key in ShopData.UPGRADES:
		_add_upgrade_row(upgrades, key)

	col.add_child(UI.spacer(4))
	var go := UI.button(_continue_text, true, Vector2(280, 50), 24)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func() -> void: continue_pressed.emit())
	col.add_child(go)
	go.grab_focus()

	panel.reset_size()
	panel.position = (Vector2(1280, 720) - panel.get_combined_minimum_size()) * 0.5

	GameState.coins_changed.connect(_on_coins_changed)
	_refresh()


func _add_brick_row(col: VBoxContainer, key: String) -> void:
	var info: Dictionary = BrickData.TYPES[key]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	var pic := TextureRect.new()
	pic.texture = ArtData.texture(info["art"])
	pic.custom_minimum_size = Vector2(64, 22)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pic)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	text.add_child(UI.label("%s   HP %d" % [info["name"], info["hp"]], 18))
	text.add_child(UI.label(info["desc"], 13, UI.INK_SOFT))
	var have := UI.label("", 15, UI.INK_SOFT)
	have.custom_minimum_size = Vector2(70, 0)
	have.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(have)
	var one := UI.button("", true, Vector2(84, 38), 15)
	one.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	one.pressed.connect(_on_buy_bricks.bind(key, 1))
	row.add_child(one)
	var many := UI.button("", true, Vector2(96, 38), 15)
	many.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	many.pressed.connect(_on_buy_bricks.bind(key, ShopData.BRICK_BUY_MANY))
	row.add_child(many)
	_brick_rows[key] = {"one": one, "many": many, "have": have}


func _add_upgrade_row(col: VBoxContainer, key: String) -> void:
	var info: Dictionary = ShopData.UPGRADES[key]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	text.add_child(UI.label(info["name"], 18))
	text.add_child(UI.label(info["desc"], 13, UI.INK_SOFT))
	var pips_box := HBoxContainer.new()
	pips_box.add_theme_constant_override("separation", 4)
	pips_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pips_box)
	var pips: Array[ColorRect] = []
	for i in range(GameState.upgrade_max_level(key)):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(12, 12)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips_box.add_child(pip)
		pips.append(pip)
	var b := UI.button("", true, Vector2(104, 38), 15)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_on_buy.bind(key))
	row.add_child(b)
	_rows[key] = {"button": b, "pips": pips}


func _on_buy(key: String) -> void:
	if GameState.buy_upgrade(key):
		GameState.audio.play("buy")
	_refresh()


func _on_buy_bricks(key: String, count: int) -> void:
	if GameState.buy_bricks(key, count):
		GameState.audio.play("buy")
	_refresh()


func _on_coins_changed(_coins: int) -> void:
	_refresh()


func _refresh() -> void:
	_coins_label.text = str(GameState.coins)
	for key in _brick_rows:
		var r: Dictionary = _brick_rows[key]
		var cost := GameState.brick_cost(key)
		(r["have"] as Label).text = "have %d" % GameState.brick_count(key)
		var one: Button = r["one"]
		one.text = "+1  (%d)" % cost
		one.disabled = GameState.coins < cost
		var many: Button = r["many"]
		many.text = "+%d  (%d)" % [ShopData.BRICK_BUY_MANY, cost * ShopData.BRICK_BUY_MANY]
		many.disabled = GameState.coins < cost * ShopData.BRICK_BUY_MANY
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
