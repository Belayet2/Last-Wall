## Shared look for all UI: a light "parchment" theme. Tune colors here.

const ArtData = preload("res://scripts/data/art_data.gd")

const PAPER := Color(0.99, 0.96, 0.88, 0.94)      # panel background
const BORDER := Color8(168, 122, 64)               # panel border (warm brown)
const INK := Color8(64, 44, 28)                    # main text on panels
const INK_SOFT := Color8(128, 102, 74)             # small text on panels
const ACCENT := Color8(200, 128, 20)               # gold-orange highlights (coins, wall number)
const BUTTON := Color8(250, 202, 84)               # main button
const BUTTON_ALT := Color8(240, 230, 206)          # second button
const BUTTON_OFF := Color8(222, 214, 198)          # disabled button
const HP_BG := Color8(222, 210, 188)
const HP_GOOD := Color8(96, 190, 84)
const HP_MID := Color8(236, 170, 50)
const HP_LOW := Color8(224, 76, 60)
const WORLD_TEXT := Color8(255, 251, 238)          # big text drawn over the field
const WORLD_OUTLINE := Color8(84, 56, 30)
const DIM := Color(0.25, 0.2, 0.12, 0.28)          # screen tint behind popups
const PIP_ON := Color8(236, 170, 40)
const PIP_OFF := Color8(214, 202, 180)
const BOSS_BAR := Color8(214, 66, 52)
const BANNER := Color8(255, 214, 120)              # big boss announcements


## opaque = no see-through (for big panels over busy backgrounds).
static func panel(h_margin: float = 14.0, v_margin: float = 8.0, opaque: bool = false) -> PanelContainer:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(PAPER, 1.0) if opaque else PAPER
	sb.border_color = BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = h_margin
	sb.content_margin_right = h_margin
	sb.content_margin_top = v_margin
	sb.content_margin_bottom = v_margin
	sb.shadow_color = Color(0.3, 0.2, 0.1, 0.25)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Plain label for panels (no outline).
static func label(text: String, font_size: int, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Big label drawn over the game world (light text with a dark outline).
static func world_label(text: String, font_size: int) -> Label:
	var l := label(text, font_size, WORLD_TEXT)
	l.add_theme_color_override("font_outline_color", WORLD_OUTLINE)
	l.add_theme_constant_override("outline_size", 8)
	return l


static func centered(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func icon(key: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = ArtData.texture(key)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = ArtData.size_of(key)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func button(text: String, primary: bool = true, min_size: Vector2 = Vector2(190, 46), font_size: int = 22) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, INK)
	b.add_theme_color_override("font_disabled_color", INK_SOFT)
	var base := BUTTON if primary else BUTTON_ALT
	var looks := {"normal": base, "hover": base.lightened(0.15), "pressed": base.darkened(0.12), "disabled": BUTTON_OFF}
	for state in looks:
		var sb := StyleBoxFlat.new()
		sb.bg_color = looks[state]
		sb.border_color = BORDER
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		b.add_theme_stylebox_override(state, sb)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = INK
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(9)
	focus.expand_margin_left = 3
	focus.expand_margin_right = 3
	focus.expand_margin_top = 3
	focus.expand_margin_bottom = 3
	b.add_theme_stylebox_override("focus", focus)
	b.pressed.connect(func() -> void: GameState.audio.play("click"))
	return b


static func spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
