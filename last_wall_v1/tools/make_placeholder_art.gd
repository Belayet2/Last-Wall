extends SceneTree
## Draws the placeholder PNGs into assets/sprites/.
## Run from the project folder:
##   godot --headless --path . --script res://tools/make_placeholder_art.gd
## Existing files are NOT overwritten (so your own art is safe).
## Add "-- --force" to redraw everything, or "-- --only=hero,shield" to redraw some files.

const OUT := "res://assets/sprites/"
const INK := Color8(28, 22, 20)

const STEEL := Color8(176, 182, 194)
const STEEL_LIGHT := Color8(224, 228, 236)
const STEEL_DARK := Color8(108, 113, 126)
const MAIL := Color8(124, 128, 140)
const LEATHER := Color8(92, 60, 36)
const WOOD := Color8(140, 90, 48)
const WOOD_DARK := Color8(96, 60, 32)
const WALL_STONE := Color8(206, 196, 174)
const MORTAR := Color8(158, 148, 130)
const ROYAL := Color8(46, 88, 180)
const ROYAL_DARK := Color8(30, 58, 128)
const ROYAL_LIGHT := Color8(84, 126, 214)
const GOLD := Color8(230, 188, 76)
const ENEMY_RED := Color8(150, 40, 40)
const ENEMY_SKIN := Color8(196, 150, 110)
const ROCK := Color8(170, 162, 152)
const SKY_TOP := Color8(108, 174, 236)
const SKY_LOW := Color8(206, 232, 248)

var rng := RandomNumberGenerator.new()
var force := false
var only: PackedStringArray = []


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--force":
			force = true
		elif arg.begins_with("--only="):
			only = arg.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(OUT)
	_save("hero", _hero)
	_save("shield", _shield)
	_save("shadow", _shadow)
	_save("stone", _stone)
	_save("stone_returned", _stone_returned)
	_save("enemy_slinger", _slinger.bind(false))
	_save("enemy_slinger_windup", _slinger.bind(true))
	_save("enemy_catapult", _catapult.bind(false))
	_save("enemy_catapult_windup", _catapult.bind(true))
	# (bricks: tools/make_brick_art.gd; cannon, cannonball and coins: tools/make_cannon_coin_art.gd)
	for n in range(1, 5):
		_save("ruins_%d" % n, _ruins.bind(n + 1))
	_save("sea", _sea)
	_save("beach", _beach)
	_save("ship", _ship)
	_save("ground", _ground)
	_save("path", _path)
	_save("edge_rocks", _edge_rocks)
	_save("marker", _marker)
	_save("icon_wall", _icon_wall)
	_save("icon_slinger", _icon_slinger)
	_save("icon_catapult", _icon_catapult)
	_save("story_throne_room", _throne_room)
	_save("portrait_king", _portrait_king)
	_save("portrait_commander", _portrait_commander)
	_save("portrait_messenger", _portrait_messenger)
	_save("story_map", _story_map.bind(false))
	_save("story_kings", _story_kings)
	_save("story_field", _story_field)
	_save("story_ships", _story_ships)
	_save("story_map_fallen", _story_map.bind(true))
	_save("story_king_calls", _story_king_calls)
	_save("story_hero", _story_hero)
	quit()


func _save(file_name: String, maker: Callable) -> void:
	var file_path := OUT + file_name + ".png"
	if not only.is_empty():
		if not only.has(file_name):
			return
	elif FileAccess.file_exists(file_path) and not force:
		print("skip (exists): ", file_path)
		return
	rng.seed = hash(file_name)
	var img: Image = maker.call()
	img.save_png(file_path)
	print("wrote: ", file_path)


# ---------------------------------------------------------------- helpers

func _img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)


func _put(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


func _blend(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, img.get_pixel(x, y).blend(c))


func _inside(x: float, y: float, cx: float, cy: float, rx: float, ry: float) -> bool:
	var dx := (x + 0.5 - cx) / rx
	var dy := (y + 0.5 - cy) / ry
	return dx * dx + dy * dy <= 1.0


func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			if _inside(x, y, cx, cy, rx, ry):
				if c.a < 1.0:
					_blend(img, x, y, c)
				else:
					_put(img, x, y, c)


func _circle(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	_ellipse(img, cx, cy, r, r, c)


func _line(img: Image, x0: float, y0: float, x1: float, y1: float, c: Color, thick: int = 1) -> void:
	var steps := int(maxf(absf(x1 - x0), absf(y1 - y0))) + 1
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := int(lerpf(x0, x1, t))
		var y := int(lerpf(y0, y1, t))
		_rect(img, x - (thick >> 1), y - (thick >> 1), thick, thick, c)


func _clear(img: Image, x: int, y: int, w: int, h: int) -> void:
	_rect(img, x, y, w, h, Color(0, 0, 0, 0))


## Sprinkles random lighter/darker pixels over the opaque area of a rect.
func _speckle(img: Image, area: Rect2i, count: int, amount: float) -> void:
	for i in range(count):
		var x := rng.randi_range(area.position.x, area.end.x - 1)
		var y := rng.randi_range(area.position.y, area.end.y - 1)
		if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
			continue
		var c := img.get_pixel(x, y)
		if c.a < 0.5:
			continue
		var k := rng.randf_range(-amount, amount)
		img.set_pixel(x, y, Color(clampf(c.r + k, 0, 1), clampf(c.g + k, 0, 1), clampf(c.b + k, 0, 1), c.a))


## Dark 1px outline around every opaque shape (makes everything readable).
func _outline(img: Image, c: Color = INK) -> void:
	var src := img.duplicate() as Image
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.5:
					img.set_pixel(x, y, c)
					break


## Brick pattern inside a rect (used by walls).
func _bricks(img: Image, area: Rect2i, base: Color, mortar: Color, bw: int, bh: int, vary: float) -> void:
	var row := 0
	var y := area.position.y
	while y < area.end.y:
		var offset := (bw >> 1) if row % 2 == 1 else 0
		var x := area.position.x - offset
		while x < area.end.x:
			var k := rng.randf_range(-vary, vary)
			var c := Color(clampf(base.r + k, 0, 1), clampf(base.g + k, 0, 1), clampf(base.b + k * 0.8, 0, 1))
			var x0 := maxi(x, area.position.x)
			var x1 := mini(x + bw - 1, area.end.x)
			var y1 := mini(y + bh - 1, area.end.y)
			_rect(img, x0, y, x1 - x0, y1 - y, c)
			_rect(img, x0, y, x1 - x0, 1, c.lightened(0.12))
			_rect(img, x0, y1, x1 - x0, 1, mortar)
			if x1 < area.end.x:
				_rect(img, x1, y, 1, y1 - y + 1, mortar)
			x += bw
		y += bh
		row += 1


func _sky_color(y: float) -> Color:
	return SKY_TOP.lerp(SKY_LOW, clampf(y / 96.0, 0.0, 1.0))


# ---------------------------------------------------------------- hero + shield

## The hero seen from BEHIND (he faces the enemies at the top of the screen).
## Blue cape = the kingdom's color. Left arm raised to hold the shield, sword in the right hand.
func _hero() -> Image:
	var img := _img(80, 104)
	var glove := Color8(74, 48, 30)
	# legs and boots (below the cape)
	_rect(img, 30, 84, 8, 14, Color8(70, 56, 46))
	_rect(img, 42, 84, 8, 14, Color8(70, 56, 46))
	_rect(img, 29, 96, 10, 8, Color8(50, 36, 30))
	_rect(img, 41, 96, 10, 8, Color8(50, 36, 30))
	# cape (widens toward the bottom)
	for y in range(40, 90):
		var t := float(y - 40) / 50.0
		var hw := int(lerpf(15.0, 23.0, t))
		_rect(img, 40 - hw, y, hw * 2, 1, ROYAL)
	_line(img, 34, 46, 29, 87, ROYAL_DARK, 2)
	_line(img, 40, 46, 40, 87, ROYAL_DARK, 2)
	_line(img, 46, 46, 51, 87, ROYAL_DARK, 2)
	_line(img, 36, 47, 32, 85, ROYAL_LIGHT, 1)
	_line(img, 42, 47, 44, 85, ROYAL_LIGHT, 1)
	for x in range(17, 63):
		var hem := 87 + (1 if (x >> 2) % 2 == 0 else 0)
		_rect(img, x, hem, 1, 2, GOLD)
	# left arm raised up to the shield strap
	_line(img, 26, 42, 22, 20, MAIL, 7)
	_circle(img, 22, 17, 4.5, glove)
	# right arm down, holding a sword pointing at the ground
	_rect(img, 59, 70, 3, 28, STEEL_LIGHT)
	_rect(img, 60, 72, 1, 24, STEEL_DARK)
	_line(img, 55, 44, 60, 64, MAIL, 7)
	_rect(img, 54, 68, 13, 3, GOLD)
	_circle(img, 60, 66, 4, glove)
	# shoulder plates
	_ellipse(img, 28, 42, 9, 6, STEEL.darkened(0.12))
	_ellipse(img, 52, 42, 9, 6, STEEL.darkened(0.12))
	_ellipse(img, 26, 40, 3, 1.5, STEEL_LIGHT)
	_ellipse(img, 50, 40, 3, 1.5, STEEL_LIGHT)
	# head from behind: mail neck guard, helmet, plume
	_rect(img, 32, 32, 16, 8, MAIL)
	for i in range(0, 16, 3):
		_rect(img, 32 + i, 35, 1, 1, STEEL_DARK)
		_rect(img, 33 + i, 37, 1, 1, STEEL_DARK)
	_ellipse(img, 40, 25, 11, 11, STEEL)
	_ellipse(img, 36, 21, 4, 3, STEEL_LIGHT)
	_rect(img, 29, 31, 22, 3, STEEL_DARK)
	_ellipse(img, 40, 15, 3.5, 10, Color8(238, 230, 206))
	_rect(img, 41, 8, 1, 16, Color8(198, 184, 150))
	_outline(img)
	return img


## Big round shield seen from behind (we see its back: wood, strap, rim).
## It is drawn BEHIND the hero, so his head and shoulders cover its lower middle.
func _shield() -> Image:
	var img := _img(88, 72)
	_ellipse(img, 44, 37, 42, 34, STEEL_DARK)
	_ellipse(img, 44, 35, 42, 33, STEEL)
	_ellipse(img, 44, 34, 40, 30, STEEL_LIGHT)
	_ellipse(img, 44, 37, 36, 28, WOOD)
	for px in range(14, 76, 10):
		for y in range(0, 72):
			if _inside(px, y, 44, 37, 36, 28):
				_put(img, px, y, WOOD_DARK)
	_ellipse(img, 44, 37, 8, 7, WOOD_DARK)
	_rect(img, 18, 34, 52, 5, LEATHER)
	for sx in range(20, 68, 4):
		_rect(img, sx, 36, 2, 1, LEATHER.lightened(0.25))
	for i in range(10):
		var a := TAU * float(i) / 10.0
		var rx := 44.0 + cos(a) * 38.5
		var ry := 35.5 + sin(a) * 31.0
		_rect(img, int(rx), int(ry), 2, 2, STEEL_DARK)
	_outline(img)
	return img


## Soft shadow under characters (keeps them on the ground).
func _shadow() -> Image:
	var img := _img(64, 16)
	for y in range(16):
		for x in range(64):
			var dx := (x + 0.5 - 32.0) / 32.0
			var dy := (y + 0.5 - 8.0) / 8.0
			var d := dx * dx + dy * dy
			if d <= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0.38 * (1.0 - d)))
	return img


# ---------------------------------------------------------------- stones

func _stone() -> Image:
	var img := _img(24, 24)
	_circle(img, 12, 12, 10.5, Color8(112, 106, 96))
	_circle(img, 11, 11, 8.5, Color8(134, 128, 116))
	_circle(img, 9, 9, 4, Color8(160, 154, 142))
	_circle(img, 8, 8, 1.8, Color8(196, 190, 178))
	_speckle(img, Rect2i(0, 0, 24, 24), 40, 0.08)
	_outline(img)
	return img


## A stone touched by the golden shield aura.
func _stone_returned() -> Image:
	var img := _img(28, 28)
	for y in range(28):
		for x in range(28):
			var d := Vector2(x + 0.5 - 14, y + 0.5 - 14).length()
			if d <= 13.5:
				var a := clampf(1.0 - d / 13.5, 0, 1) * 0.85
				img.set_pixel(x, y, Color(1.0, 0.8, 0.25, a))
	_circle(img, 14, 14, 9, INK)
	_circle(img, 14, 14, 8, Color8(226, 178, 70))
	_circle(img, 12, 12, 4.5, Color8(250, 214, 110))
	_circle(img, 11, 11, 2, Color8(255, 248, 220))
	return img


# ---------------------------------------------------------------- enemies (they face the camera)

func _thrower(windup: bool) -> Image:
	var img := _img(48, 56)
	var tunic := ENEMY_RED
	_rect(img, 15, 44, 7, 11, Color8(64, 44, 38))
	_rect(img, 26, 44, 7, 11, Color8(64, 44, 38))
	_rect(img, 7, 26, 6, 15, tunic.darkened(0.2))
	_circle(img, 10, 42, 3, ENEMY_SKIN)
	if windup:
		_rect(img, 35, 8, 6, 20, tunic.darkened(0.2))
		_circle(img, 38, 7, 5.5, Color8(126, 120, 110))
	else:
		_rect(img, 35, 26, 6, 15, tunic.darkened(0.2))
		_circle(img, 38, 43, 5, Color8(126, 120, 110))
	_rect(img, 12, 24, 24, 22, tunic)
	_rect(img, 12, 38, 24, 3, Color8(70, 50, 40))
	_rect(img, 14, 26, 3, 10, tunic.lightened(0.2))
	_circle(img, 24, 16, 8, ENEMY_SKIN)
	_ellipse(img, 24, 11, 9, 5.5, Color8(66, 60, 66))
	_rect(img, 23, 1, 2, 6, Color8(66, 60, 66))
	_rect(img, 19, 16, 3, 2, INK)
	_rect(img, 26, 16, 3, 2, INK)
	_rect(img, 20, 21, 8, 3, Color8(90, 60, 40))
	_outline(img)
	return img


func _slinger(windup: bool) -> Image:
	var img := _img(40, 48)
	var cloth := Color8(120, 56, 44)
	_rect(img, 13, 38, 6, 10, Color8(64, 44, 38))
	_rect(img, 21, 38, 6, 10, Color8(64, 44, 38))
	_rect(img, 10, 20, 20, 20, cloth)
	_rect(img, 10, 33, 20, 2, Color8(70, 50, 40))
	if windup:
		_rect(img, 30, 6, 5, 16, cloth.darkened(0.2))
		_ellipse(img, 26, 5, 13, 4, Color(0.85, 0.85, 0.8, 0.45))   # spinning sling
		_circle(img, 37, 4, 2.5, Color8(126, 120, 110))
	else:
		_rect(img, 30, 22, 5, 12, cloth.darkened(0.2))
		_line(img, 33, 34, 34, 42, Color8(90, 70, 50))
		_circle(img, 34, 43, 2.5, Color8(126, 120, 110))
	_circle(img, 20, 13, 7, ENEMY_SKIN)
	_ellipse(img, 20, 10, 8.5, 6, cloth.darkened(0.3))
	_rect(img, 16, 13, 2, 2, INK)
	_rect(img, 22, 13, 2, 2, INK)
	_outline(img)
	return img


## Catapult FACING the hero (front view), with a red crewman working the lever.
## Windup = arm pulled back low with a boulder in the bucket.
## Standing = arm up against the top bar (it just fired; the boulder leaves from the top).
func _catapult(windup: bool) -> Image:
	var img := _img(80, 64)
	var boulder := Color8(126, 120, 110)
	# back wheels peeking out, base frame, front wheels
	_rect(img, 4, 44, 8, 18, WOOD_DARK)
	_rect(img, 52, 44, 8, 18, WOOD_DARK)
	_rect(img, 6, 46, 4, 14, STEEL_DARK)
	_rect(img, 54, 46, 4, 14, STEEL_DARK)
	_rect(img, 10, 46, 44, 9, WOOD)
	_rect(img, 10, 46, 44, 2, WOOD.lightened(0.2))
	# uprights and the top bar the arm hits
	_rect(img, 14, 16, 5, 31, WOOD_DARK)
	_rect(img, 45, 16, 5, 31, WOOD_DARK)
	_rect(img, 12, 14, 40, 6, WOOD)
	_rect(img, 12, 14, 40, 1, WOOD.lightened(0.25))
	_rect(img, 27, 14, 10, 6, LEATHER)
	if windup:
		_rect(img, 30, 30, 4, 18, WOOD.darkened(0.1))      # arm pulled back (short, low)
		_ellipse(img, 32, 30, 7, 4, WOOD_DARK)               # bucket
		_circle(img, 32, 26, 6, boulder)                      # loaded boulder
		_circle(img, 30, 24, 2, boulder.lightened(0.25))
		_line(img, 34, 40, 63, 36, Color8(150, 120, 80))     # rope to the crewman
	else:
		_rect(img, 30, 6, 4, 42, WOOD)                       # arm up against the bar
		_ellipse(img, 32, 6, 7, 4, WOOD_DARK)                # empty bucket
	# crewman (enemy soldier) at the lever
	var tunic := ENEMY_RED
	_rect(img, 63, 54, 4, 9, Color8(64, 44, 38))
	_rect(img, 69, 54, 4, 9, Color8(64, 44, 38))
	_rect(img, 61, 38, 14, 17, tunic)
	_rect(img, 61, 50, 14, 2, Color8(70, 50, 40))
	_circle(img, 68, 32, 6, ENEMY_SKIN)
	_ellipse(img, 68, 28, 7, 4, Color8(66, 60, 66))
	_rect(img, 65, 32, 2, 2, INK)
	_rect(img, 70, 32, 2, 2, INK)
	if windup:
		_rect(img, 58, 38, 5, 4, ENEMY_SKIN)                 # hands pulling the rope
	else:
		_rect(img, 74, 26, 4, 12, tunic.darkened(0.2))      # arm raised: "fire!"
		_circle(img, 76, 25, 2.5, ENEMY_SKIN)
	_outline(img)
	return img


# ---------------------------------------------------------------- world (full 1280 width)

## The 5 walls look different. 1 = innermost (the Last Wall) ... 5 = the Sea Wall on the shore.
const WALL_STYLES := [
	{},  # (unused, walls are numbered from 1)
	{"stone": Color8(228, 222, 208), "mortar": Color8(180, 172, 156), "bw": 42, "bh": 14, "extra": "plain"},
	{"stone": Color8(224, 192, 136), "mortar": Color8(178, 144, 94), "bw": 32, "bh": 12, "extra": "sand"},
	{"stone": Color8(194, 104, 78), "mortar": Color8(232, 214, 190), "bw": 22, "bh": 9, "extra": "brick"},
	{"stone": Color8(168, 176, 152), "mortar": Color8(122, 132, 110), "bw": 36, "bh": 16, "extra": "moss"},
	{"stone": Color8(146, 164, 178), "mortar": Color8(104, 120, 134), "bw": 50, "bh": 18, "extra": "sea"},
]


func _wall(damage: int, style_index: int = 1) -> Image:
	var style: Dictionary = WALL_STYLES[style_index]
	var stone: Color = style["stone"]
	var mortar: Color = style["mortar"]
	var extra: String = style["extra"]
	var w := 1280
	var h := 96
	var img := _img(w, h)
	for mx in range(0, w, 50):
		_bricks(img, Rect2i(mx + 5, 0, 30, 20), stone, mortar, 15, 10, 0.05)
	_bricks(img, Rect2i(0, 18, w, h - 18), stone, mortar, style["bw"], style["bh"], 0.06)
	_rect(img, 0, 18, w, 2, stone.lightened(0.2))
	match extra:
		"brick":
			var band := Color8(238, 228, 208)
			_bricks(img, Rect2i(0, 18, w, 7), band, Color8(200, 188, 166), 40, 7, 0.02)
			_bricks(img, Rect2i(0, 86, w, 10), band, Color8(200, 188, 166), 40, 10, 0.02)
		"sand":
			for i in range(40):
				var sy := rng.randi_range(24, 90)
				_rect(img, rng.randi_range(0, w - 80), sy, rng.randi_range(30, 80), 1, stone.darkened(0.12))
		"moss":
			for i in range(60):
				var mx := rng.randf_range(0, w)
				var my := rng.randf_range(20, 94) if rng.randf() < 0.4 else rng.randf_range(80, 96)
				_ellipse(img, mx, my, rng.randf_range(6, 18), rng.randf_range(3, 6), Color(0.42, 0.6, 0.28, 0.75))
			for i in range(14):                       # ivy hanging from the top
				var ix := rng.randf_range(10, w - 10)
				var ylen := rng.randi_range(20, 60)
				for k in range(0, ylen, 3):
					_circle(img, ix + sin(k * 0.3) * 3.0, 20 + k, 2.2, Color8(88, 140, 60))
		"sea":
			_rect(img, 0, 80, w, 16, Color(0.2, 0.35, 0.45, 0.25))  # wet, darker base
			for i in range(80):
				_ellipse(img, rng.randf_range(0, w), rng.randf_range(86, 96), rng.randf_range(4, 10), rng.randf_range(2, 5), Color(0.3, 0.42, 0.22, 0.85))
			for i in range(260):
				_circle(img, rng.randf_range(0, w), rng.randf_range(60, 94), 1.2, Color8(226, 222, 210))
	# the kingdom's banners (blue, like the hero's cape)
	for bx in [430, 830]:
		if damage == 2 and bx == 830:
			continue
		var bh := 22 if damage == 2 else 40
		_rect(img, bx - 2, 22, 26, 3, WOOD_DARK)
		_rect(img, bx, 24, 22, bh, ROYAL)
		_rect(img, bx, 24, 22, 2, GOLD)
		_rect(img, bx + 9, 32, 4, 12 if bh > 30 else 6, GOLD)
		if bh > 30:
			_rect(img, bx + 5, 36, 12, 3, GOLD)
	# the door (decoration)
	var dcx := w >> 1
	var frame := stone.darkened(0.45)
	_circle(img, dcx, 54, 37, frame)
	_rect(img, dcx - 37, 54, 74, 42, frame)
	if damage < 2:
		_circle(img, dcx, 56, 31, WOOD)
		_rect(img, dcx - 31, 56, 62, 40, WOOD)
		for px in range(dcx - 30, dcx + 31, 10):
			_rect(img, px, 26, 1, 70, WOOD_DARK)
		_rect(img, dcx - 31, 64, 62, 3, Color8(60, 60, 66))
		_rect(img, dcx - 31, 84, 62, 3, Color8(60, 60, 66))
		_circle(img, dcx + 18, 76, 3, Color8(200, 170, 70))
	else:
		_circle(img, dcx, 58, 30, Color8(40, 34, 30))
		_rect(img, dcx - 30, 58, 60, 38, Color8(40, 34, 30))
		_line(img, dcx - 26, 92, dcx - 6, 60, WOOD_DARK, 4)
		_line(img, dcx + 22, 94, dcx + 10, 72, WOOD, 3)

	var crack := stone.darkened(0.45)
	if damage >= 1:
		var crack_count := 12 if damage == 1 else 24
		for i in range(crack_count):
			var x := rng.randf_range(20, w - 20)
			var y := 18.0
			for s in range(rng.randi_range(3, 6)):
				var nx := x + rng.randf_range(-14, 14)
				var ny := y + rng.randf_range(8, 18)
				_line(img, x, y, nx, ny, crack, 2)
				x = nx
				y = ny
		for mx in range(0, w, 50):
			if rng.randf() < (0.3 if damage == 1 else 0.8):
				_clear(img, mx + 4, 0, 32, rng.randi_range(8, 20))
		for i in range(16 if damage == 1 else 44):
			var bx := rng.randi_range(0, w - 40)
			if absi(bx - dcx) < 60:
				continue
			_rect(img, bx, rng.randi_range(22, 80), rng.randi_range(14, 34), rng.randi_range(6, 12), stone.darkened(0.25))
	if damage >= 2:
		var top := 22.0
		for x in range(w):
			top = clampf(top + rng.randf_range(-3, 3), 18, 48)
			if absi(x - dcx) > 40:
				_clear(img, x, 0, 1, int(top))
		for i in range(120):
			var rx := rng.randf_range(0, w)
			var r := rng.randf_range(3, 8)
			_circle(img, rx, h - rng.randf_range(2, 10), r, stone.darkened(rng.randf_range(0.05, 0.35)))
	_speckle(img, Rect2i(0, 0, w, h), 5000, 0.05)
	_outline(img)
	return img

func _ground() -> Image:
	var w := 1280
	var h := 400
	var img := _img(w, h)
	for y in range(h):
		var t := float(y) / h
		_rect(img, 0, y, w, 1, Color8(124, 176, 82).lerp(Color8(146, 198, 96), t))
	_speckle(img, Rect2i(0, 0, w, h), 26000, 0.06)
	for i in range(280):
		var x := rng.randi_range(2, w - 3)
		var y := rng.randi_range(4, h - 2)
		var c := Color8(92, 142, 60)
		_rect(img, x, y - 3, 1, 3, c)
		_rect(img, x + 2, y - 4, 1, 4, c)
	for i in range(70):
		_ellipse(img, rng.randf_range(0, w), rng.randf_range(0, h), rng.randf_range(10, 30), rng.randf_range(4, 9), Color8(180, 164, 112, 110))
	for i in range(90):
		_circle(img, rng.randf_range(0, w), rng.randf_range(0, h), rng.randf_range(1.5, 3), Color8(184, 178, 164))
	return img


func _path() -> Image:
	var w := 1280
	var h := 76
	var img := _img(w, h)
	_rect(img, 0, 0, w, h, Color8(216, 190, 142))
	_rect(img, 0, 0, w, 4, Color8(178, 150, 106))
	_rect(img, 0, h - 3, w, 3, Color8(178, 150, 106))
	_speckle(img, Rect2i(0, 0, w, h), 10000, 0.05)
	for i in range(200):
		_circle(img, rng.randf_range(0, w), rng.randf_range(6, h - 6), rng.randf_range(1, 2.5), Color8(186, 172, 150))
	return img


## Sky with soft clouds (used by the ruins and the sea).
func _sky(img: Image, h: int) -> void:
	for y in range(h):
		_rect(img, 0, y, img.get_width(), 1, _sky_color(y))
	for cx in [180.0, 520.0, 860.0, 1150.0]:
		var cy := rng.randf_range(16, 36)
		for k in range(6):
			_ellipse(img, cx + k * 14 - 35 + rng.randf_range(-5, 5), cy + rng.randf_range(-4, 4), rng.randf_range(14, 22), rng.randf_range(7, 11), Color(1, 1, 1, 0.55))


## The enemy side for walls 1-4: the NEXT wall out (style_index), captured and in ruins.
func _ruins(style_index: int) -> Image:
	var style: Dictionary = WALL_STYLES[style_index]
	var w := 1280
	var h := 150
	var img := _img(w, h)
	_sky(img, h)
	var enemy_stone: Color = (style["stone"] as Color).lerp(Color8(150, 146, 150), 0.35)
	var mortar: Color = (style["mortar"] as Color).lerp(Color8(110, 106, 112), 0.35)
	_bricks(img, Rect2i(0, 56, w, 94), enemy_stone, mortar, style["bw"], style["bh"], 0.05)
	var top := 70.0
	for x in range(w):
		var corner := 1.0 - clampf(minf(x, w - x) / 70.0, 0.0, 1.0)
		top = clampf(top + rng.randf_range(-2.5, 2.5), 62, 96)
		var cut := int(lerpf(top, 58.0, corner))
		for y in range(56, cut):
			img.set_pixel(x, y, _sky_color(y))
		img.set_pixel(x, cut, enemy_stone.darkened(0.4))
	for i in range(9):
		var hx := rng.randf_range(40, w - 40)
		var hy := rng.randf_range(102, 124)
		var hr := rng.randf_range(7, 14)
		_ellipse(img, hx, hy, hr + 2, hr * 0.6 + 2, enemy_stone.darkened(0.15))
		_ellipse(img, hx, hy + 1, hr, hr * 0.6, enemy_stone.darkened(0.3))
	for bx in [390, 890]:
		_rect(img, bx, 30, 2, 50, Color8(60, 44, 34))
		_rect(img, bx + 2, 32, 20, 24, Color8(150, 30, 30))
	_rect(img, 0, 136, w, 14, enemy_stone.darkened(0.08))
	for i in range(140):
		_circle(img, rng.randf_range(0, w), rng.randf_range(132, 148), rng.randf_range(2, 6), enemy_stone.darkened(rng.randf_range(0, 0.3)))
	_speckle(img, Rect2i(0, 56, w, 94), 5000, 0.05)
	return img


## The enemy side for wall 5: open sea, the enemy fleet far away, a strip of beach.
func _sea() -> Image:
	var w := 1280
	var h := 150
	var img := _img(w, h)
	_sky(img, 52)
	for y in range(48, h):
		var t := float(y - 48) / float(h - 48)
		_rect(img, 0, y, w, 1, Color8(86, 150, 206).lerp(Color8(74, 164, 204), t))
	for i in range(160):
		var wx := rng.randf_range(0, w)
		var wy := rng.randf_range(54, 148)
		_rect(img, int(wx), int(wy), rng.randi_range(6, 18), 1, Color(1, 1, 1, 0.35))
	# far away enemy ships near the horizon
	for sx in [120, 260, 980, 1110, 1200]:
		_rect(img, sx, 46, 18, 4, Color8(90, 60, 40))
		_rect(img, sx + 8, 34, 1, 12, Color8(70, 50, 34))
		_rect(img, sx + 3, 35, 11, 8, Color8(196, 70, 60))
	return img


## Field for wall 5: the sea continues at the top (the flagship floats there), then the beach.
func _beach() -> Image:
	var w := 1280
	var h := 400
	var img := _img(w, h)
	for y in range(h):
		var t := float(y) / h
		_rect(img, 0, y, w, 1, Color8(226, 206, 160).lerp(Color8(214, 194, 146), t))
	_speckle(img, Rect2i(0, 0, w, h), 26000, 0.04)
	# sea at the top, with a wavy shoreline and foam
	for x in range(w):
		var shore := 62 + int(sin(x * 0.025) * 3.0 + sin(x * 0.07) * 1.5)
		for y in range(shore):
			img.set_pixel(x, y, Color8(74, 164, 204).lerp(Color8(96, 190, 210), float(y) / 62.0))
		_rect(img, x, shore, 1, 6, Color8(200, 186, 146))           # wet sand
		_rect(img, x, shore - 2, 1, 3, Color(1, 1, 1, 0.9))          # foam
	for i in range(70):
		_rect(img, rng.randi_range(0, w - 20), rng.randi_range(4, 50), rng.randi_range(6, 18), 1, Color(1, 1, 1, 0.35))
	for i in range(80):
		_ellipse(img, rng.randf_range(0, w), rng.randf_range(80, h), rng.randf_range(12, 34), rng.randf_range(3, 7), Color8(204, 182, 134, 120))
	for i in range(60):                         # shells
		var c := Color8(250, 236, 226) if rng.randf() < 0.5 else Color8(240, 196, 186)
		_ellipse(img, rng.randf_range(0, w), rng.randf_range(80, h), 2.5, 1.8, c)
	for i in range(10):                         # driftwood
		var dx := rng.randf_range(40, w - 80)
		var dy := rng.randf_range(90, h - 20)
		_line(img, dx, dy, dx + rng.randf_range(20, 50), dy + rng.randf_range(-6, 6), Color8(150, 116, 80), 3)
	for i in range(60):                         # beach grass near our wall
		var gx := rng.randi_range(2, w - 3)
		var gy := rng.randi_range(h - 120, h - 2)
		_rect(img, gx, gy - 4, 1, 4, Color8(130, 160, 80))
		_rect(img, gx + 2, gy - 5, 1, 5, Color8(130, 160, 80))
	return img

## Rocky edge on the side of the field. Stones bounce off it.
## Used on the left; the right side uses the same image flipped.
func _edge_rocks() -> Image:
	var w := 40
	var h := 476
	var img := _img(w, h)
	_rect(img, 0, 0, 14, h, ROCK.darkened(0.35))
	var y := -6.0
	while y < h + 8:
		var rx := rng.randf_range(11, 16)
		var ry := rng.randf_range(8, 13)
		var cx := rng.randf_range(12, 22)
		var c := ROCK.darkened(rng.randf_range(0.0, 0.3))
		_ellipse(img, cx, y, rx, ry, c)
		_ellipse(img, cx - 3, y - 3, rx * 0.45, ry * 0.4, c.lightened(0.18))
		y += rng.randf_range(10, 16)
	_speckle(img, Rect2i(0, 0, w, h), 1500, 0.05)
	_outline(img)
	return img


func _marker() -> Image:
	var img := _img(56, 18)
	_ellipse(img, 28, 9, 27, 8.5, Color(0.95, 0.2, 0.15, 0.95))
	for y in range(18):
		for x in range(56):
			if _inside(x, y, 28, 9, 22, 6):
				img.set_pixel(x, y, Color(0.95, 0.3, 0.2, 0.3))
	return img


# ---------------------------------------------------------------- HUD icons (small, scaled up 2x in game)

func _icon_wall() -> Image:
	var img := _img(14, 14)
	_rect(img, 2, 5, 10, 9, WALL_STONE)
	for mx in [2, 6, 10]:
		_rect(img, mx, 2, 2, 3, WALL_STONE)
	_rect(img, 3, 6, 8, 1, WALL_STONE.lightened(0.25))
	_rect(img, 6, 9, 2, 5, Color8(60, 44, 32))
	_outline(img)
	return img


func _icon_coin() -> Image:
	var img := _img(12, 12)
	_circle(img, 6, 6, 5.5, Color8(190, 140, 40))
	_circle(img, 6, 6, 4.3, GOLD)
	_rect(img, 5, 3, 2, 6, Color8(190, 140, 40))
	_rect(img, 3, 3, 1, 2, Color8(255, 240, 180))
	_outline(img)
	return img


func _icon_enemy() -> Image:
	var img := _img(12, 12)
	_ellipse(img, 6, 7, 5, 4.5, Color8(80, 74, 80))
	_rect(img, 5, 0, 2, 4, Color8(80, 74, 80))
	_rect(img, 1, 8, 10, 2, ENEMY_RED)
	_rect(img, 3, 5, 2, 1, Color8(150, 146, 152))
	_outline(img)
	return img


func _icon_slinger() -> Image:
	var img := _img(12, 12)
	_ellipse(img, 6, 6, 5, 5, Color8(96, 44, 34))      # hood
	_ellipse(img, 6, 7, 3, 3, ENEMY_SKIN)              # face
	_rect(img, 4, 7, 1, 1, INK)
	_rect(img, 7, 7, 1, 1, INK)
	_outline(img)
	return img


func _icon_catapult() -> Image:
	var img := _img(14, 12)
	_rect(img, 1, 8, 12, 3, WOOD)
	_rect(img, 2, 3, 2, 6, WOOD_DARK)
	_rect(img, 10, 3, 2, 6, WOOD_DARK)
	_rect(img, 1, 2, 12, 2, WOOD)
	_circle(img, 7, 6, 2, Color8(126, 120, 110))
	_outline(img)
	return img


# ---------------------------------------------------------------- story (drawn small, scaled up in game)

const SKIN_LIGHT := Color8(236, 196, 160)


## Bright throne room (640x360, shown at 2x).
func _throne_room() -> Image:
	var w := 640
	var h := 360
	var img := _img(w, h)
	_bricks(img, Rect2i(0, 0, w, 250), Color8(228, 218, 198), Color8(194, 182, 160), 40, 20, 0.03)
	# pillars
	for px in [30, 570]:
		_rect(img, px, 0, 40, 250, Color8(238, 230, 212))
		_rect(img, px, 0, 6, 250, Color8(250, 246, 236))
		_rect(img, px + 34, 0, 6, 250, Color8(206, 196, 176))
	# tall windows with sky
	for wx in [140, 430]:
		_circle(img, wx + 35, 70, 35, Color8(170, 150, 120))
		_rect(img, wx, 70, 70, 120, Color8(170, 150, 120))
		for y in range(40, 186):
			for x in range(wx + 5, wx + 65):
				if y >= 70 or _inside(x, y, wx + 35, 70, 30, 30):
					_put(img, x, y, SKY_TOP.lerp(SKY_LOW, clampf((y - 40) / 150.0, 0, 1)))
		_rect(img, wx + 33, 40, 4, 146, Color8(170, 150, 120))
		_rect(img, wx + 5, 112, 60, 4, Color8(170, 150, 120))
	# banners of the kingdom
	for bx in [258, 362]:
		_rect(img, bx - 4, 26, 28, 4, WOOD_DARK)
		_rect(img, bx, 30, 20, 96, ROYAL)
		_rect(img, bx, 30, 20, 3, GOLD)
		_rect(img, bx + 8, 50, 4, 30, GOLD)
		_rect(img, bx + 2, 58, 16, 4, GOLD)
	# floor tiles
	for y in range(250, h, 20):
		for x in range(0, w, 40):
			var c := Color8(214, 184, 140) if ((int(x / 40.0) + int(y / 20.0)) % 2 == 0) else Color8(200, 168, 126)
			_rect(img, x, y, 40, 20, c)
	_rect(img, 0, 250, w, 3, Color8(176, 150, 112))
	# carpet + dais + throne
	_rect(img, 284, 250, 72, 110, ROYAL)
	_rect(img, 284, 250, 4, 110, GOLD)
	_rect(img, 352, 250, 4, 110, GOLD)
	_rect(img, 262, 228, 116, 24, Color8(232, 224, 206))
	_rect(img, 262, 228, 116, 3, Color8(248, 244, 234))
	_rect(img, 294, 120, 52, 110, GOLD)
	_circle(img, 320, 122, 26, GOLD)
	_rect(img, 302, 130, 36, 76, ROYAL)
	_circle(img, 320, 130, 18, ROYAL)
	_rect(img, 286, 196, 68, 14, GOLD.darkened(0.1))
	_rect(img, 290, 206, 60, 8, ROYAL_DARK)
	_circle(img, 320, 104, 5, Color8(220, 60, 60))
	_speckle(img, Rect2i(0, 0, w, h), 8000, 0.025)
	return img


## Shared bust shape: shoulders/body color and head.
func _bust(img: Image, body: Color, skin: Color) -> void:
	_ellipse(img, 48, 112, 46, 32, body)
	_rect(img, 40, 68, 16, 14, skin.darkened(0.12))
	_ellipse(img, 48, 54, 19, 23, skin)


func _portrait_king(robe: Color = ROYAL, gray: Color = Color8(206, 206, 212)) -> Image:
	var img := _img(96, 112)
	_bust(img, robe, SKIN_LIGHT)
	_ellipse(img, 48, 86, 30, 9, Color8(246, 246, 240))           # ermine collar
	for i in range(6):
		_rect(img, 26 + i * 9, 84 + (i % 2) * 3, 2, 2, INK)
	for i in range(9):
		_rect(img, 32 + i * 4, 95 + absi(i - 4), 3, 2, GOLD)       # gold chain
	_circle(img, 48, 104, 4, GOLD)
	_rect(img, 28, 40, 6, 24, gray)                                  # hair sides
	_rect(img, 62, 40, 6, 24, gray)
	_ellipse(img, 48, 71, 17, 15, gray)                              # beard
	_ellipse(img, 48, 62, 10, 3, gray.lightened(0.3))               # moustache
	_rect(img, 43, 66, 10, 2, Color8(140, 90, 80))
	_rect(img, 38, 48, 5, 3, Color8(250, 250, 250))
	_rect(img, 53, 48, 5, 3, Color8(250, 250, 250))
	_rect(img, 40, 49, 2, 2, INK)
	_rect(img, 55, 49, 2, 2, INK)
	_rect(img, 37, 44, 7, 2, gray.darkened(0.2))
	_rect(img, 52, 44, 7, 2, gray.darkened(0.2))
	_rect(img, 46, 51, 4, 8, SKIN_LIGHT.darkened(0.1))
	# crown
	_rect(img, 28, 26, 40, 9, GOLD)
	for cx in [30, 39, 48, 57, 64]:
		var tall := 12 if cx == 48 else 8
		_rect(img, cx, 26 - tall, 4, tall, GOLD)
		_circle(img, cx + 2, 26 - tall, 2, GOLD.lightened(0.2))
	_circle(img, 48, 30, 2.5, Color8(220, 50, 50))
	_circle(img, 37, 30, 2, Color8(60, 120, 220))
	_circle(img, 59, 30, 2, Color8(60, 120, 220))
	_rect(img, 28, 26, 40, 1, GOLD.lightened(0.35))
	_outline(img)
	return img


func _portrait_commander() -> Image:
	var img := _img(96, 112)
	var skin := Color8(222, 178, 140)
	_bust(img, STEEL, skin)
	_ellipse(img, 26, 92, 14, 9, STEEL_LIGHT)                       # shoulder plates
	_ellipse(img, 70, 92, 14, 9, STEEL_LIGHT)
	_rect(img, 32, 86, 32, 26, ROYAL)                                # tabard
	_rect(img, 46, 90, 4, 18, GOLD)
	_rect(img, 40, 96, 16, 4, GOLD)
	_rect(img, 40, 68, 16, 16, MAIL)                                 # mail neck
	_ellipse(img, 48, 54, 19, 23, skin)
	_rect(img, 37, 47, 8, 3, Color8(90, 60, 36))                     # stern brows
	_rect(img, 51, 47, 8, 3, Color8(90, 60, 36))
	_rect(img, 39, 51, 4, 2, INK)
	_rect(img, 53, 51, 4, 2, INK)
	_rect(img, 46, 52, 4, 8, skin.darkened(0.1))
	_rect(img, 38, 63, 20, 3, Color8(110, 72, 42))                   # moustache
	_rect(img, 44, 68, 8, 1, Color8(120, 70, 60))
	_line(img, 58, 47, 61, 58, Color8(196, 120, 108))                # scar
	# helmet with nasal guard and blue plume
	_ellipse(img, 48, 18, 6, 11, ROYAL_LIGHT)
	_ellipse(img, 48, 35, 22, 12, STEEL)
	_ellipse(img, 42, 30, 7, 3, STEEL_LIGHT)
	_rect(img, 26, 41, 44, 4, STEEL_DARK)
	_rect(img, 46, 41, 4, 13, STEEL_DARK)
	_outline(img)
	return img


func _portrait_messenger() -> Image:
	var img := _img(96, 112)
	var brown := Color8(124, 82, 46)
	_bust(img, Color8(96, 152, 204), SKIN_LIGHT)
	_line(img, 28, 84, 68, 112, LEATHER, 5)                          # bag strap
	_ellipse(img, 48, 37, 21, 13, brown)                             # messy hair
	for hx in [30, 38, 56, 64]:
		_rect(img, hx, 28, 4, 8, brown)
	_rect(img, 37, 49, 7, 6, Color8(250, 250, 250))                  # wide eyes
	_rect(img, 52, 49, 7, 6, Color8(250, 250, 250))
	_rect(img, 39, 51, 3, 3, INK)
	_rect(img, 54, 51, 3, 3, INK)
	_rect(img, 37, 44, 7, 2, brown)                                  # raised brows
	_rect(img, 52, 44, 7, 2, brown)
	_rect(img, 46, 55, 4, 6, SKIN_LIGHT.darkened(0.1))
	_ellipse(img, 48, 67, 5, 4.5, Color8(130, 40, 40))               # shouting mouth
	_ellipse(img, 36, 60, 4, 2, Color(0.95, 0.5, 0.5, 0.5))          # out of breath
	_ellipse(img, 60, 60, 4, 2, Color(0.95, 0.5, 0.5, 0.5))
	_ellipse(img, 70, 42, 2, 3.5, Color8(170, 214, 244))             # sweat
	_ellipse(img, 25, 52, 2, 3.5, Color8(170, 214, 244))
	_outline(img)
	return img


# ---------------------------------------------------------------- boss

## The enemy flagship, side view (it sails left/right, its cannons face the shore).
## Bow points RIGHT. Gun ports (cannon muzzles) at x = 40, 70, 100, 130, y = 74.
func _ship() -> Image:
	var img := _img(180, 100)
	var hull := Color8(132, 86, 50)
	var hull_dark := Color8(96, 60, 36)
	var sail := Color8(206, 64, 54)
	# masts and sails
	_rect(img, 68, 6, 4, 58, hull_dark)
	_rect(img, 114, 4, 4, 60, hull_dark)
	for s in [[48, 14, 44, 34], [94, 10, 44, 38]]:
		for y in range(s[1], s[1] + s[3]):
			var bulge := int(sin(float(y - s[1]) / s[3] * PI) * 4.0)
			_rect(img, s[0] - bulge, y, s[2] + bulge * 2, 1, sail)
		_rect(img, s[0] - 2, s[1], s[2] + 4, 2, hull_dark)
	_circle(img, 70, 31, 7, Color8(245, 236, 220))          # emblem on the sails
	_circle(img, 116, 29, 7, Color8(245, 236, 220))
	_rect(img, 68, 29, 5, 4, sail)
	_rect(img, 114, 27, 5, 4, sail)
	_rect(img, 118, 0, 12, 7, Color8(40, 36, 40))           # black flag
	# stern castle (left) and bow (right)
	_rect(img, 8, 46, 34, 18, hull)
	_rect(img, 8, 46, 34, 3, hull.lightened(0.2))
	_rect(img, 14, 52, 5, 5, Color8(250, 210, 120))
	_rect(img, 26, 52, 5, 5, Color8(250, 210, 120))
	# hull
	for y in range(60, 94):
		var t := float(y - 60) / 34.0
		var left := int(lerpf(6, 30, t * t))
		var right := int(lerpf(178, 150, t))
		_rect(img, left, y, right - left, 1, hull if (y % 10) < 5 else hull.darkened(0.08))
	_rect(img, 6, 60, 172, 3, hull.lightened(0.25))
	_rect(img, 20, 68, 136, 13, Color8(150, 40, 40))         # red gun deck band
	for px in [40, 70, 100, 130]:
		_circle(img, px, 74, 5, Color8(40, 38, 42))
		_circle(img, px, 74, 3, Color8(16, 14, 16))
	_line(img, 166, 60, 179, 50, hull_dark, 3)               # bowsprit
	for x in range(20, 160):                                 # foam at the waterline
		_rect(img, x, 92 + int(sin(x * 0.4) * 1.5), 1, 2, Color(1, 1, 1, 0.9))
	_outline(img)
	return img


## Iron cannonball.
func _cannonball() -> Image:
	var img := _img(24, 24)
	_circle(img, 12, 12, 10.5, Color8(56, 56, 62))
	_circle(img, 11, 11, 8, Color8(76, 76, 84))
	_circle(img, 8, 8, 3, Color8(130, 130, 140))
	_circle(img, 7, 7, 1.3, Color8(210, 210, 220))
	_outline(img)
	return img


# ---------------------------------------------------------------- narrated story pictures (640x360, shown at 2x)

func _paste(dst: Image, src: Image, x: int, y: int, scale: float = 1.0) -> void:
	var s := src.duplicate() as Image
	if scale != 1.0:
		s.resize(int(s.get_width() * scale), int(s.get_height() * scale), Image.INTERPOLATE_NEAREST)
	dst.blend_rect(s, Rect2i(0, 0, s.get_width(), s.get_height()), Vector2i(x, y))


func _ring(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color, broken: bool) -> void:
	var steps := int(TAU * maxf(rx, ry))
	for i in range(steps):
		var a := TAU * i / steps
		if broken and fmod(a * 3.0 + rx * 0.05, 1.0) < 0.35:
			continue
		var x := cx + cos(a) * rx
		var y := cy + sin(a) * ry
		_rect(img, int(x) - 2, int(y) - 2, 5, 5, c.darkened(0.35))
		_rect(img, int(x) - 1, int(y) - 1, 3, 3, c)


## The island seen from above: five rings of walls around the old town.
func _story_map(fallen: bool) -> Image:
	var w := 640
	var h := 360
	var img := _img(w, h)
	for y in range(h):
		_rect(img, 0, y, w, 1, Color8(84, 156, 210).lerp(Color8(110, 180, 222), float(y) / h))
	for i in range(140):
		_rect(img, rng.randi_range(0, w - 12), rng.randi_range(0, h - 1), rng.randi_range(4, 12), 1, Color(1, 1, 1, 0.3))
	var cx := 320.0
	var cy := 185.0
	_ellipse(img, cx, cy, 268, 168, Color8(226, 206, 156))                  # beach
	for i in range(30):                                                      # bumpy coast
		var a := TAU * i / 30.0
		_circle(img, cx + cos(a) * 262, cy + sin(a) * 162, rng.randf_range(14, 24), Color8(226, 206, 156))
	_ellipse(img, cx, cy, 252, 152, Color8(132, 186, 92))                   # grass
	_speckle(img, Rect2i(60, 30, 520, 320), 9000, 0.05)
	for i in range(70):                                                      # little houses
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(0.15, 0.9)
		var hx := cx + cos(a) * 225 * r
		var hy := cy + sin(a) * 135 * r
		_rect(img, int(hx), int(hy), 6, 5, Color8(236, 226, 206))
		_rect(img, int(hx) - 1, int(hy) - 3, 8, 3, Color8(196, 92, 70))
	for k in range(5, 0, -1):                                                # five walls
		var style: Dictionary = WALL_STYLES[k]
		var c: Color = style["stone"]
		var broken := fallen and k > 1
		_ring(img, cx, cy, 30.0 + k * 42.0, 18.0 + k * 25.0, c, broken)
		if broken:
			for i in range(5):
				var a := rng.randf_range(0, TAU)
				var fx := cx + cos(a) * (30.0 + k * 42.0)
				var fy := cy + sin(a) * (18.0 + k * 25.0)
				_circle(img, fx, fy - 4, 4, Color8(250, 150, 50))
				_circle(img, fx, fy - 10, 5, Color(0.4, 0.4, 0.42, 0.6))
	if fallen:
		_ring(img, cx, cy, 72, 43, Color8(255, 220, 110), false)            # the Last Wall still stands
		for i in range(9):                                                   # enemy ships around the island
			var a := TAU * i / 9.0 + 0.2
			var sx := cx + cos(a) * 300
			var sy := cy + sin(a) * 190
			_rect(img, int(sx) - 8, int(sy), 16, 4, Color8(100, 66, 40))
			_rect(img, int(sx) - 4, int(sy) - 10, 9, 9, Color8(206, 64, 54))
	# the keep in the middle
	_rect(img, int(cx) - 10, int(cy) - 14, 20, 18, Color8(236, 230, 214))
	_rect(img, int(cx) - 12, int(cy) - 18, 6, 6, Color8(236, 230, 214))
	_rect(img, int(cx) + 6, int(cy) - 18, 6, 6, Color8(236, 230, 214))
	_rect(img, int(cx), int(cy) - 30, 1, 14, Color8(90, 70, 50))
	_rect(img, int(cx) + 1, int(cy) - 30, 9, 6, ROYAL)
	_outline(img)
	return img


## Five painted kings in the royal hall.
func _story_kings() -> Image:
	var img := _throne_room()
	var robes := [ROYAL, Color8(120, 70, 160), Color8(60, 130, 90), Color8(170, 70, 60), Color8(50, 110, 160)]
	var hairs := [Color8(214, 214, 220), Color8(150, 100, 60), Color8(80, 60, 50), Color8(230, 200, 120), Color8(190, 190, 196)]
	_rect(img, 0, 30, 640, 230, Color(0.98, 0.95, 0.88, 0.85))
	for i in range(5):
		var x := 18 + i * 124
		_rect(img, x - 6, 48, 116, 150, GOLD)
		_rect(img, x - 2, 52, 108, 142, GOLD.darkened(0.25))
		_rect(img, x, 54, 104, 138, Color8(236, 226, 200))
		_paste(img, _portrait_king(robes[i], hairs[i]), x + 4, 66, 1.0)
		_rect(img, x + 22, 204, 60, 12, GOLD)                                # name plate
		_rect(img, x + 24, 206, 56, 8, GOLD.darkened(0.2))
	return img


## After the war: swords in the ground with helmets, the Last Wall far away.
func _story_field() -> Image:
	var w := 640
	var h := 360
	var img := _img(w, h)
	for y in range(160):
		_rect(img, 0, y, w, 1, Color8(150, 196, 236).lerp(Color8(236, 214, 180), float(y) / 160.0))
	_rect(img, 0, 120, w, 26, Color8(226, 220, 206))                         # the Last Wall far away
	for mx in range(0, w, 16):
		_rect(img, mx, 114, 9, 7, Color8(226, 220, 206))
	for y in range(146, h):
		_rect(img, 0, y, w, 1, Color8(126, 176, 86).lerp(Color8(110, 160, 76), float(y - 146) / 214.0))
	_speckle(img, Rect2i(0, 146, w, 214), 9000, 0.05)
	for i in range(160):                                                     # little flowers
		_circle(img, rng.randf_range(0, w), rng.randf_range(150, h), 1.5, Color8(250, 240, 120) if rng.randf() < 0.5 else Color8(250, 250, 250))
	for row in range(5):                                                     # rows of swords, far to near
		var y := 170 + row * 38
		var s := 0.6 + row * 0.22
		for i in range(8 - row):
			var x := 40 + i * (560.0 / (8 - row)) + rng.randf_range(-14, 14) + row * 10
			var blade := int(26 * s)
			_rect(img, int(x), y - blade, maxi(2, int(3 * s)), blade, STEEL_LIGHT)
			_rect(img, int(x - 6 * s), y - blade, int(15 * s), maxi(2, int(3 * s)), GOLD)
			_ellipse(img, x + 1, y - blade - 6 * s, 9 * s, 7 * s, STEEL)        # helmet on the hilt
			_rect(img, int(x - 8 * s), int(y - blade - 4 * s), int(18 * s), maxi(1, int(2 * s)), STEEL_DARK)
	_outline(img)
	return img


## Watchmen's view from the Sea Wall: red sails everywhere.
func _story_ships() -> Image:
	var w := 640
	var h := 360
	var img := _img(w, h)
	for y in range(130):
		_rect(img, 0, y, w, 1, SKY_TOP.lerp(SKY_LOW, float(y) / 130.0))
	for y in range(130, h):
		_rect(img, 0, y, w, 1, Color8(86, 150, 206).lerp(Color8(70, 168, 204), float(y - 130) / 230.0))
	for i in range(160):
		_rect(img, rng.randi_range(0, w - 14), rng.randi_range(134, h - 1), rng.randi_range(5, 14), 1, Color(1, 1, 1, 0.3))
	for i in range(26):                                                      # the fleet, far to near
		var d := float(i) / 26.0
		var s := 0.4 + d * 1.6
		var sx := rng.randf_range(10, w - 40)
		var sy := 136.0 + d * 150.0
		_rect(img, int(sx), int(sy), int(30 * s), int(6 * s), Color8(110, 72, 44))
		_rect(img, int(sx + 14 * s), int(sy - 22 * s), maxi(1, int(2 * s)), int(22 * s), Color8(80, 56, 36))
		_rect(img, int(sx + 6 * s), int(sy - 20 * s), int(18 * s), int(14 * s), Color8(206, 64, 54))
	var style: Dictionary = WALL_STYLES[5]                                     # the Sea Wall in front
	_bricks(img, Rect2i(0, 312, w, 48), style["stone"], style["mortar"], 40, 14, 0.05)
	for mx in range(0, w, 50):
		_bricks(img, Rect2i(mx + 6, 296, 30, 18), style["stone"], style["mortar"], 15, 9, 0.05)
	_outline(img)
	return img


## The king calls the hero: throne room, the king on his throne, the hero (from behind) before him.
func _story_king_calls() -> Image:
	var img := _throne_room()
	_paste(img, _portrait_king(), 272, 98, 1.0)
	_paste(img, _shield(), 272, 232, 1.1)       # hero (from behind) stands below the throne
	_paste(img, _hero(), 276, 256, 1.1)
	return img


## The hero at the Last Wall, looking out at the enemy.
func _story_hero() -> Image:
	var img := _img(640, 360)
	var top := _ruins(2)
	top.resize(640, 75, Image.INTERPOLATE_NEAREST)
	var ground := _ground()
	ground.resize(640, 200, Image.INTERPOLATE_NEAREST)
	var path := _path()
	path.resize(640, 38, Image.INTERPOLATE_NEAREST)
	var wall := _wall(0, 1)
	wall.resize(640, 48, Image.INTERPOLATE_NEAREST)
	_paste(img, top, 0, 0)
	_paste(img, ground, 0, 75)
	_paste(img, path, 0, 275)
	_paste(img, wall, 0, 312)
	_paste(img, _shield(), 276, 180)            # shield centered 36 px above the hero's center
	_paste(img, _hero(), 280, 200)
	return img
