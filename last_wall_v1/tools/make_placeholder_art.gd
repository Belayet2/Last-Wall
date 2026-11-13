extends SceneTree
## Draws the placeholder PNGs into assets/sprites/.
## Run from the project folder:
##   godot --headless --path . --script res://tools/make_placeholder_art.gd
## Existing files are NOT overwritten (so your own art is safe).
## Add "-- --force" at the end to redraw everything.

const OUT := "res://assets/sprites/"
const INK := Color8(28, 22, 20)

const SKIN := Color8(232, 190, 150)
const STEEL := Color8(172, 178, 190)
const STEEL_DARK := Color8(110, 115, 128)
const WOOD := Color8(140, 90, 48)
const WOOD_DARK := Color8(98, 60, 32)
const WALL_STONE := Color8(156, 146, 128)
const MORTAR := Color8(104, 96, 84)

var rng := RandomNumberGenerator.new()
var force := false


func _init() -> void:
	force = "--force" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(OUT)
	_save("hero", _hero())
	_save("shield", _shield())
	_save("stone", _stone())
	_save("stone_returned", _stone_returned())
	_save("enemy_thrower", _thrower())
	_save("enemy_slinger", _slinger())
	_save("enemy_catapult", _catapult())
	_save("wall_whole", _wall(0))
	_save("wall_cracked", _wall(1))
	_save("wall_broken", _wall(2))
	_save("ground", _ground())
	_save("path", _path())
	_save("ruins", _ruins())
	_save("side_panel", _side_panel())
	_save("marker", _marker())
	quit()


func _save(file_name: String, img: Image) -> void:
	var file_path := OUT + file_name + ".png"
	if FileAccess.file_exists(file_path) and not force:
		print("skip (exists): ", file_path)
		return
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


func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
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


## Brick pattern inside a rect (used by walls and panels).
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
			# top light edge for a little depth
			_rect(img, x0, y, x1 - x0, 1, c.lightened(0.12))
			_rect(img, x0, y1, x1 - x0, 1, mortar)
			if x1 < area.end.x:
				_rect(img, x1, y, 1, y1 - y + 1, mortar)
			x += bw
		y += bh
		row += 1


# ---------------------------------------------------------------- sprites

func _hero() -> Image:
	var img := _img(48, 64)
	var tunic := Color8(48, 96, 180)
	# legs + boots
	_rect(img, 15, 50, 8, 10, Color8(78, 60, 44))
	_rect(img, 25, 50, 8, 10, Color8(78, 60, 44))
	_rect(img, 14, 58, 10, 6, Color8(52, 38, 30))
	_rect(img, 24, 58, 10, 6, Color8(52, 38, 30))
	# arms raised up to hold the shield
	_rect(img, 7, 6, 6, 26, tunic.darkened(0.15))
	_rect(img, 35, 6, 6, 26, tunic.darkened(0.15))
	_circle(img, 10, 5, 3.5, SKIN)
	_circle(img, 38, 5, 3.5, SKIN)
	# body
	_rect(img, 13, 28, 22, 24, tunic)
	_rect(img, 15, 30, 4, 14, tunic.lightened(0.25))
	_rect(img, 13, 44, 22, 4, Color8(92, 60, 30))
	_rect(img, 22, 44, 4, 4, Color8(230, 190, 70))
	# head + helmet
	_circle(img, 24, 20, 8.5, SKIN)
	_ellipse(img, 24, 15, 9.5, 6.5, STEEL)
	_rect(img, 15, 15, 19, 3, STEEL_DARK)
	_rect(img, 23, 15, 2, 8, STEEL_DARK)
	_rect(img, 19, 21, 2, 2, INK)
	_rect(img, 27, 21, 2, 2, INK)
	_rect(img, 20, 12, 4, 2, STEEL.lightened(0.4))
	_outline(img)
	return img


func _shield() -> Image:
	var img := _img(160, 28)
	_rect(img, 14, 2, 132, 24, STEEL)
	_circle(img, 14, 14, 12, STEEL)
	_circle(img, 146, 14, 12, STEEL)
	_rect(img, 14, 6, 132, 16, WOOD)
	_circle(img, 14, 14, 8, WOOD)
	_circle(img, 146, 14, 8, WOOD)
	for gy in [9, 13, 18]:
		_line(img, 10, gy, 150, gy, WOOD_DARK)
	for rx in range(20, 150, 20):
		_rect(img, rx, 3, 2, 2, STEEL_DARK)
		_rect(img, rx, 23, 2, 2, STEEL_DARK)
	_circle(img, 80, 14, 8, STEEL_DARK)
	_circle(img, 80, 14, 6, STEEL)
	_circle(img, 78, 12, 2, Color8(240, 240, 245))
	_rect(img, 16, 3, 128, 1, STEEL.lightened(0.4))
	_outline(img)
	return img


func _stone() -> Image:
	var img := _img(24, 24)
	_circle(img, 12, 12, 10.5, Color8(112, 106, 96))
	_circle(img, 11, 11, 8.5, Color8(134, 128, 116))
	_circle(img, 9, 9, 4, Color8(160, 154, 142))
	_circle(img, 8, 8, 1.8, Color8(196, 190, 178))
	_speckle(img, Rect2i(0, 0, 24, 24), 40, 0.08)
	_outline(img)
	return img


func _stone_returned() -> Image:
	var img := _img(28, 28)
	# soft golden glow
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


func _thrower() -> Image:
	var img := _img(48, 56)
	var tunic := Color8(150, 40, 40)
	var skin := Color8(196, 150, 110)
	_rect(img, 15, 44, 7, 11, Color8(64, 44, 38))
	_rect(img, 26, 44, 7, 11, Color8(64, 44, 38))
	_rect(img, 7, 26, 6, 15, tunic.darkened(0.2))
	_circle(img, 10, 42, 3, skin)
	_rect(img, 35, 8, 6, 20, tunic.darkened(0.2))   # throwing arm (raised)
	_circle(img, 38, 7, 5.5, Color8(126, 120, 110))  # stone in hand
	_rect(img, 12, 24, 24, 22, tunic)
	_rect(img, 12, 38, 24, 3, Color8(70, 50, 40))
	_rect(img, 14, 26, 3, 10, tunic.lightened(0.2))
	_circle(img, 24, 16, 8, skin)
	_ellipse(img, 24, 11, 9, 5.5, Color8(66, 60, 66))
	_rect(img, 23, 1, 2, 6, Color8(66, 60, 66))
	_rect(img, 19, 16, 3, 2, INK)
	_rect(img, 26, 16, 3, 2, INK)
	_rect(img, 20, 21, 8, 3, Color8(90, 60, 40))     # beard
	_outline(img)
	return img


func _slinger() -> Image:
	var img := _img(40, 48)
	var cloth := Color8(96, 104, 52)
	var skin := Color8(196, 150, 110)
	_rect(img, 13, 38, 6, 10, Color8(64, 44, 38))
	_rect(img, 21, 38, 6, 10, Color8(64, 44, 38))
	_rect(img, 10, 20, 20, 20, cloth)
	_rect(img, 10, 33, 20, 2, Color8(70, 50, 40))
	_rect(img, 30, 10, 5, 14, cloth.darkened(0.2))
	_line(img, 33, 10, 37, 2, Color8(90, 70, 50))   # sling cord
	_circle(img, 37, 3, 2.5, Color8(126, 120, 110))
	_circle(img, 20, 13, 7, skin)
	_ellipse(img, 20, 10, 8.5, 6, cloth.darkened(0.25))  # hood
	_rect(img, 16, 13, 2, 2, INK)
	_rect(img, 22, 13, 2, 2, INK)
	_outline(img)
	return img


func _catapult() -> Image:
	var img := _img(80, 64)
	_rect(img, 6, 44, 68, 8, WOOD)
	_rect(img, 6, 44, 68, 2, WOOD.lightened(0.2))
	_line(img, 24, 44, 40, 24, WOOD_DARK, 4)
	_line(img, 56, 44, 40, 24, WOOD_DARK, 4)
	_line(img, 30, 42, 70, 10, WOOD, 4)              # throwing arm
	_ellipse(img, 70, 9, 7, 5, WOOD_DARK)            # bucket
	_circle(img, 70, 5, 5, Color8(126, 120, 110))    # boulder
	_circle(img, 18, 54, 9, WOOD_DARK)
	_circle(img, 62, 54, 9, WOOD_DARK)
	_circle(img, 18, 54, 3, STEEL_DARK)
	_circle(img, 62, 54, 3, STEEL_DARK)
	_outline(img)
	return img


func _wall(damage: int) -> Image:
	var w := 760
	var h := 96
	var img := _img(w, h)
	rng.seed = 11
	# merlons on top
	for mx in range(0, w, 50):
		_bricks(img, Rect2i(mx + 5, 0, 30, 20), WALL_STONE, MORTAR, 15, 10, 0.05)
	_bricks(img, Rect2i(0, 18, w, h - 18), WALL_STONE, MORTAR, 38, 13, 0.06)
	_rect(img, 0, 18, w, 2, WALL_STONE.lightened(0.2))
	# door (decoration)
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
		_line(img, dcx - 26, 92, dcx - 6, 60, WOOD_DARK, 4)  # broken plank
		_line(img, dcx + 22, 94, dcx + 10, 72, WOOD, 3)

	var crack := Color8(54, 48, 44)
	if damage >= 1:
		rng.seed = 23
		var crack_count := 7 if damage == 1 else 14
		for i in range(crack_count):
			var x := rng.randf_range(20, w - 20)
			var y := 18.0
			for s in range(rng.randi_range(3, 6)):
				var nx := x + rng.randf_range(-14, 14)
				var ny := y + rng.randf_range(8, 18)
				_line(img, x, y, nx, ny, crack, 2)
				x = nx
				y = ny
		# missing merlons and bricks
		for mx in range(0, w, 50):
			if rng.randf() < (0.3 if damage == 1 else 0.8):
				_clear(img, mx + 4, 0, 32, rng.randi_range(8, 20))
		for i in range(10 if damage == 1 else 26):
			var bx := rng.randi_range(0, w - 40)
			if absi(bx - dcx) < 60:
				continue
			_rect(img, bx, rng.randi_range(22, 80), rng.randi_range(14, 34), rng.randi_range(6, 12), Color8(88, 80, 70))
	if damage >= 2:
		# jagged broken top
		var top := 22.0
		for x in range(w):
			top = clampf(top + rng.randf_range(-3, 3), 18, 48)
			if absi(x - dcx) > 40:
				_clear(img, x, 0, 1, int(top))
		# rubble along the bottom
		for i in range(70):
			var rx := rng.randf_range(0, w)
			var r := rng.randf_range(3, 8)
			var c := WALL_STONE.darkened(rng.randf_range(0.05, 0.35))
			_circle(img, rx, h - rng.randf_range(2, 10), r, c)
	_speckle(img, Rect2i(0, 0, w, h), 3000, 0.05)
	_outline(img)
	return img


func _ground() -> Image:
	var w := 760
	var h := 400
	var img := _img(w, h)
	rng.seed = 5
	for y in range(h):
		var t := float(y) / h
		var c := Color8(92, 104, 58).lerp(Color8(112, 126, 66), t)
		_rect(img, 0, y, w, 1, c)
	_speckle(img, Rect2i(0, 0, w, h), 14000, 0.06)
	# grass tufts
	for i in range(160):
		var x := rng.randi_range(2, w - 3)
		var y := rng.randi_range(4, h - 2)
		var c := Color8(70, 88, 44)
		_rect(img, x, y - 3, 1, 3, c)
		_rect(img, x + 2, y - 4, 1, 4, c)
	# small rocks and dirt patches
	for i in range(40):
		_ellipse(img, rng.randf_range(0, w), rng.randf_range(0, h), rng.randf_range(10, 30), rng.randf_range(4, 9), Color8(122, 110, 76, 120))
	for i in range(50):
		var x := rng.randf_range(0, w)
		var y := rng.randf_range(0, h)
		_circle(img, x, y, rng.randf_range(1.5, 3), Color8(140, 134, 120))
	return img


func _path() -> Image:
	var w := 760
	var h := 76
	var img := _img(w, h)
	rng.seed = 9
	_rect(img, 0, 0, w, h, Color8(156, 126, 86))
	_rect(img, 0, 0, w, 4, Color8(118, 94, 62))
	_rect(img, 0, h - 3, w, 3, Color8(118, 94, 62))
	_speckle(img, Rect2i(0, 0, w, h), 6000, 0.05)
	for i in range(120):
		_circle(img, rng.randf_range(0, w), rng.randf_range(6, h - 6), rng.randf_range(1, 2.5), Color8(124, 112, 96))
	return img


func _ruins() -> Image:
	var w := 760
	var h := 150
	var img := _img(w, h)
	rng.seed = 3
	# dusky sky
	for y in range(h):
		var c := Color8(58, 66, 96).lerp(Color8(168, 118, 102), clampf(float(y) / 90.0, 0, 1))
		_rect(img, 0, y, w, 1, c)
	# smoke columns far away
	for i in range(4):
		var sx := rng.randf_range(40, w - 40)
		for k in range(8):
			_circle(img, sx + k * 4 + rng.randf_range(-4, 4), 70 - k * 9, 8 + k * 1.5, Color(0.25, 0.22, 0.24, 0.25))
	# the captured outer wall: dark, broken
	var enemy_stone := Color8(92, 86, 94)
	_bricks(img, Rect2i(0, 60, w, 90), enemy_stone, Color8(62, 58, 66), 34, 12, 0.05)
	var top := 70.0
	for x in range(w):
		top = clampf(top + rng.randf_range(-2.5, 2.5), 58, 96)
		var y := 60
		while y < int(top):
			var c := Color8(58, 66, 96).lerp(Color8(168, 118, 102), clampf(float(y) / 90.0, 0, 1))
			img.set_pixel(x, y, c)
			y += 1
		img.set_pixel(x, int(top), Color8(40, 36, 42))
	# holes in the wall
	for i in range(10):
		_ellipse(img, rng.randf_range(20, w - 20), rng.randf_range(100, 130), rng.randf_range(8, 20), rng.randf_range(5, 10), Color8(40, 36, 42))
	# enemy banners
	for i in range(3):
		var bx := 120 + i * 260 + rng.randi_range(-30, 30)
		_rect(img, bx, 22, 2, 52, Color8(60, 44, 34))
		_rect(img, bx + 2, 24, 18, 22, Color8(150, 30, 30))
		_clear(img, bx + 12, 40, 8, 6)
	# rubble ledge where enemies stand
	_rect(img, 0, 136, w, 14, Color8(76, 70, 70))
	for i in range(80):
		_circle(img, rng.randf_range(0, w), rng.randf_range(132, 148), rng.randf_range(2, 6), enemy_stone.darkened(rng.randf_range(0, 0.3)))
	_speckle(img, Rect2i(0, 60, w, 90), 3000, 0.05)
	return img


func _side_panel() -> Image:
	var w := 260
	var h := 720
	var img := _img(w, h)
	rng.seed = 17
	_bricks(img, Rect2i(0, 0, w, h), Color8(52, 48, 56), Color8(32, 30, 36), 52, 26, 0.04)
	_rect(img, w - 6, 0, 6, h, Color8(30, 28, 32))
	_rect(img, w - 8, 0, 2, h, Color8(90, 84, 92))
	_speckle(img, Rect2i(0, 0, w, h), 4000, 0.04)
	return img


func _marker() -> Image:
	var img := _img(48, 16)
	_ellipse(img, 24, 8, 23, 7.5, Color(0.95, 0.2, 0.15, 0.9))
	_ellipse(img, 24, 8, 19, 5, Color(0.95, 0.3, 0.2, 0.35))
	return img
