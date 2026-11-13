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
	_save("enemy_thrower", _thrower.bind(false))
	_save("enemy_thrower_windup", _thrower.bind(true))
	_save("enemy_slinger", _slinger.bind(false))
	_save("enemy_slinger_windup", _slinger.bind(true))
	_save("enemy_catapult", _catapult.bind(false))
	_save("enemy_catapult_windup", _catapult.bind(true))
	_save("wall_whole", _wall.bind(0))
	_save("wall_cracked", _wall.bind(1))
	_save("wall_broken", _wall.bind(2))
	_save("ground", _ground)
	_save("path", _path)
	_save("ruins", _ruins)
	_save("edge_rocks", _edge_rocks)
	_save("marker", _marker)
	_save("icon_wall", _icon_wall)
	_save("icon_coin", _icon_coin)
	_save("icon_enemy", _icon_enemy)
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


func _catapult(windup: bool) -> Image:
	var img := _img(80, 64)
	_rect(img, 6, 44, 68, 8, WOOD)
	_rect(img, 6, 44, 68, 2, WOOD.lightened(0.2))
	_line(img, 24, 44, 40, 26, WOOD_DARK, 4)
	_line(img, 56, 44, 40, 26, WOOD_DARK, 4)
	if windup:
		_line(img, 36, 30, 72, 40, WOOD, 4)        # arm pulled back, loaded
		_ellipse(img, 72, 38, 7, 5, WOOD_DARK)
		_circle(img, 72, 34, 5.5, Color8(126, 120, 110))
	else:
		_line(img, 40, 30, 60, 6, WOOD, 4)         # arm up, empty
		_ellipse(img, 61, 6, 7, 5, WOOD_DARK)
	_circle(img, 18, 54, 9, WOOD_DARK)
	_circle(img, 62, 54, 9, WOOD_DARK)
	_circle(img, 18, 54, 3, STEEL_DARK)
	_circle(img, 62, 54, 3, STEEL_DARK)
	_outline(img)
	return img


# ---------------------------------------------------------------- world (full 1280 width)

func _wall(damage: int) -> Image:
	var w := 1280
	var h := 96
	var img := _img(w, h)
	for mx in range(0, w, 50):
		_bricks(img, Rect2i(mx + 5, 0, 30, 20), WALL_STONE, MORTAR, 15, 10, 0.05)
	_bricks(img, Rect2i(0, 18, w, h - 18), WALL_STONE, MORTAR, 38, 13, 0.06)
	_rect(img, 0, 18, w, 2, WALL_STONE.lightened(0.2))
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
			_clear(img, bx + 8, 24 + bh - 6, 6, 6)
	# the door (decoration)
	var dcx := w >> 1
	var frame := Color8(72, 62, 52)
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
		_circle(img, dcx, 58, 30, Color8(24, 20, 18))
		_rect(img, dcx - 30, 58, 60, 38, Color8(24, 20, 18))
		_line(img, dcx - 26, 92, dcx - 6, 60, WOOD_DARK, 4)
		_line(img, dcx + 22, 94, dcx + 10, 72, WOOD, 3)

	var crack := Color8(112, 102, 92)
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
			_rect(img, bx, rng.randi_range(22, 80), rng.randi_range(14, 34), rng.randi_range(6, 12), Color8(160, 150, 132))
	if damage >= 2:
		var top := 22.0
		for x in range(w):
			top = clampf(top + rng.randf_range(-3, 3), 18, 48)
			if absi(x - dcx) > 40:
				_clear(img, x, 0, 1, int(top))
		for i in range(120):
			var rx := rng.randf_range(0, w)
			var r := rng.randf_range(3, 8)
			_circle(img, rx, h - rng.randf_range(2, 10), r, WALL_STONE.darkened(rng.randf_range(0.05, 0.35)))
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


## The enemy side: the captured outer wall in ruins, red enemy banners, dusk sky.
func _ruins() -> Image:
	var w := 1280
	var h := 150
	var img := _img(w, h)
	for y in range(h):
		_rect(img, 0, y, w, 1, _sky_color(y))
	# soft white clouds
	for cx in [180.0, 520.0, 860.0, 1150.0]:
		var cy := rng.randf_range(18, 40)
		for k in range(6):
			_ellipse(img, cx + k * 14 - 35 + rng.randf_range(-5, 5), cy + rng.randf_range(-4, 4), rng.randf_range(14, 22), rng.randf_range(7, 11), Color(1, 1, 1, 0.55))
	var enemy_stone := Color8(162, 156, 162)
	_bricks(img, Rect2i(0, 56, w, 94), enemy_stone, Color8(124, 118, 126), 34, 12, 0.05)
	# broken top edge (higher at the corners: stumps of old towers)
	var top := 70.0
	for x in range(w):
		var corner := 1.0 - clampf(minf(x, w - x) / 70.0, 0.0, 1.0)
		top = clampf(top + rng.randf_range(-2.5, 2.5), 62, 96)
		var cut := int(lerpf(top, 58.0, corner))
		for y in range(56, cut):
			img.set_pixel(x, y, _sky_color(y))
		img.set_pixel(x, cut, Color8(104, 98, 106))
	# a few dark gaps in the broken wall (soft, not pure black)
	for i in range(9):
		var hx := rng.randf_range(40, w - 40)
		var hy := rng.randf_range(102, 124)
		var hr := rng.randf_range(7, 14)
		_ellipse(img, hx, hy, hr + 2, hr * 0.6 + 2, Color8(134, 128, 136))
		_ellipse(img, hx, hy + 1, hr, hr * 0.6, Color8(112, 106, 116))
	for bx in [390, 890]:
		_rect(img, bx, 30, 2, 50, Color8(60, 44, 34))
		_rect(img, bx + 2, 32, 20, 24, Color8(150, 30, 30))
		_clear(img, bx + 13, 50, 9, 6)
	_rect(img, 0, 136, w, 14, Color8(150, 142, 136))
	for i in range(140):
		_circle(img, rng.randf_range(0, w), rng.randf_range(132, 148), rng.randf_range(2, 6), enemy_stone.darkened(rng.randf_range(0, 0.3)))
	_speckle(img, Rect2i(0, 56, w, 94), 5000, 0.05)
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
