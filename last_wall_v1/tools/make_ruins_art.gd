extends SceneTree
## Draws the enemy side for walls 1-4 (ruins_1 .. ruins_4): the NEXT wall out, captured and broken,
## built the same way as our wall (columns of bricks on a last layer), only further away (smaller).
## Uses the brick pictures in assets/sprites, so run it again after you change the bricks:
##   godot --headless --path . --script res://tools/make_ruins_art.gd
## ruins_N shows wall N+1: its own last layer (foundation_N+1) with your kind of bricks on top.

const OUT := "res://assets/sprites/"
const W := 1280
const H := 150
const BRICK := Vector2i(40, 14)        # far away: smaller than our 64 x 22 bricks
const ROWS := 4                        # same as our wall: last layer + 3 rows
const BASE_Y := 136                    # bottom of the far wall
const SKY_TOP := Color8(108, 174, 236)
const SKY_LOW := Color8(172, 212, 244)
const DIRT := Color8(150, 128, 92)
const GRASS := Color8(124, 176, 82)
const HAZE := 0.1                      # far things fade a little toward the sky

var rng := RandomNumberGenerator.new()
var _cache := {}


func _initialize() -> void:
	for n in range(1, 5):
		rng.seed = 7100 + n * 31
		_save(_ruins(n + 1), "ruins_%d" % n)
	quit()


func _ruins(wall_number: int) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	_sky(img)
	_ground(img)
	var cols := W / BRICK.x
	var heights := _heights(cols)
	var foundation := "foundation_%d" % wall_number
	var flags := [cols / 4, cols * 3 / 4 - 1]
	for c in range(cols):
		var x := c * BRICK.x
		for row in range(heights[c]):
			var key := foundation
			if row > 0 and c > 0 and c < cols - 1:      # the end towers are all old stone
				key = _pick_brick(foundation)
			var brick := _brick(key)
			var top_brick: bool = row == heights[c] - 1 and row > 0
			if top_brick and rng.randf() < 0.55:
				brick = _chip(brick)
			if rng.randf() < 0.3:
				brick = _with_cracks(brick, 1 if rng.randf() < 0.6 else 2)
			img.blend_rect(brick, Rect2i(Vector2i.ZERO, BRICK), Vector2i(x, BASE_Y - BRICK.y * (row + 1)))
		_shadow(img, x, BASE_Y)
	for c in flags:
		var fc: int = c
		while heights[fc] < 3 and fc < cols - 2:
			fc += 1
		_banner(img, fc * BRICK.x + BRICK.x / 2, BASE_Y - BRICK.y * heights[fc])
	_rubble(img, heights)
	return img


## Column heights: mostly standing, with breaches. The deepest breach goes through the last layer:
## that is how the enemy took this wall.
func _heights(cols: int) -> Array:
	var h := []
	for c in range(cols):
		h.append(ROWS)
	var breaches := [
		{"at": rng.randi_range(9, 13), "depth": 4.6, "width": 3.2},
		{"at": rng.randi_range(19, 23), "depth": 3.0, "width": 2.6},
		{"at": rng.randi_range(26, 29), "depth": 2.2, "width": 2.0},
		{"at": rng.randi_range(3, 5), "depth": 1.8, "width": 1.6},
	]
	for b in breaches:
		for c in range(cols):
			var d: float = absf(c - int(b["at"])) / float(b["width"])
			if d < 1.0:
				var cut := int(round(float(b["depth"]) * (1.0 - d)))
				h[c] = mini(h[c], ROWS - cut)
	for c in range(cols):
		if h[c] > 1 and rng.randf() < 0.3:
			h[c] -= 1
		h[c] = clampi(h[c], 0, ROWS)
	return h


func _pick_brick(foundation: String) -> String:
	var r := rng.randf()
	if r < 0.45:
		return foundation
	if r < 0.7:
		return "brick_clay"
	if r < 0.88:
		return "brick_stone"
	return "brick_mud"


## A brick picture shrunk to the far size, with a fresh outline, faded a little toward the sky.
func _brick(key: String) -> Image:
	if _cache.has(key):
		return _cache[key]
	var src := Image.load_from_file(ProjectSettings.globalize_path(OUT + key + ".png"))
	src.convert(Image.FORMAT_RGBA8)
	src.resize(BRICK.x, BRICK.y, Image.INTERPOLATE_LANCZOS)
	for y in range(BRICK.y):
		for x in range(BRICK.x):
			var c := src.get_pixel(x, y)
			c = Color(c.lerp(SKY_LOW, HAZE), 1.0)
			var ex := mini(x, BRICK.x - 1 - x)
			var ey := mini(y, BRICK.y - 1 - y)
			if ex == 0 and ey == 0:
				c = Color(0, 0, 0, 0)
			elif ex == 0 or ey == 0:
				c = c.darkened(0.55)
			elif y == 1:
				c = c.lightened(0.2)
			elif y == BRICK.y - 2 or x == BRICK.x - 2:
				c = c.darkened(0.25)
			src.set_pixel(x, y, c)
	_cache[key] = src
	return src


## The top brick of a broken column: a jagged chunk is knocked off one side.
func _chip(brick: Image) -> Image:
	var img := brick.duplicate()
	var from_left := rng.randf() < 0.5
	var depth := rng.randi_range(8, 22)
	for y in range(BRICK.y):
		var cut := int(depth * (1.0 - float(y) / BRICK.y) + rng.randi_range(-2, 2))
		for i in range(maxi(cut, 0)):
			var x := i if from_left else BRICK.x - 1 - i
			img.set_pixel(x, y, Color(0, 0, 0, 0))
		var edge := cut if from_left else BRICK.x - 1 - cut
		if cut >= 0 and edge >= 0 and edge < BRICK.x and img.get_pixel(edge, y).a > 0.0:
			img.set_pixel(edge, y, img.get_pixel(edge, y).darkened(0.5))
	return img


func _with_cracks(brick: Image, stage: int) -> Image:
	var key := "brick_cracks_%d" % stage
	if not _cache.has(key):
		var c := Image.load_from_file(ProjectSettings.globalize_path(OUT + key + ".png"))
		c.convert(Image.FORMAT_RGBA8)
		c.resize(BRICK.x, BRICK.y, Image.INTERPOLATE_NEAREST)
		_cache[key] = c
	var img := brick.duplicate()
	img.blend_rect(_cache[key], Rect2i(Vector2i.ZERO, BRICK), Vector2i.ZERO)
	return img


func _sky(img: Image) -> void:
	for y in range(H):
		var col := SKY_TOP.lerp(SKY_LOW, clampf(y / 96.0, 0.0, 1.0))
		for x in range(W):
			img.set_pixel(x, y, col)
	for cx in [150.0, 470.0, 820.0, 1130.0]:
		var cy := rng.randf_range(18, 40)
		for k in range(6):
			_ellipse(img, cx + k * 14 - 35 + rng.randf_range(-5, 5), cy + rng.randf_range(-4, 4), rng.randf_range(14, 22), rng.randf_range(7, 11), Color(1, 1, 1, 0.55))


## Trampled dirt at the foot of the wall, turning into the green field at the bottom edge.
func _ground(img: Image) -> void:
	for y in range(BASE_Y - 2, H):
		var t := clampf(float(y - (BASE_Y - 2)) / float(H - BASE_Y + 2), 0.0, 1.0)
		var col := DIRT.lerp(GRASS, t * t)
		for x in range(W):
			var n := rng.randf_range(-0.04, 0.04)
			img.set_pixel(x, y, Color(col.r + n, col.g + n, col.b + n))


func _shadow(img: Image, x: int, y: int) -> void:
	for i in range(BRICK.x):
		for k in range(3):
			var p := img.get_pixel(x + i, y + k)
			img.set_pixel(x + i, y + k, p.darkened(0.3 - k * 0.08))


## Bricks that fell out lie in front of the wall (more of them under the breaches), plus pebbles.
func _rubble(img: Image, heights: Array) -> void:
	var small := Vector2i(16, 6)
	for c in range(heights.size()):
		var lost: int = ROWS - heights[c]
		for i in range(lost * 2 + rng.randi_range(0, 1)):
			var key := "brick_clay" if rng.randf() < 0.4 else ("brick_stone" if rng.randf() < 0.5 else "brick_mud")
			var piece := _brick(key).duplicate()
			piece.resize(small.x, small.y, Image.INTERPOLATE_BILINEAR)
			var px := c * BRICK.x + rng.randi_range(-10, BRICK.x - 6)
			var py := rng.randi_range(BASE_Y - 3, H - 9)
			img.blend_rect(piece, Rect2i(Vector2i.ZERO, small), Vector2i(clampi(px, 0, W - small.x), py))
	for i in range(260):
		var pebble := Color8(140, 128, 112).darkened(rng.randf_range(0.0, 0.35))
		_ellipse(img, rng.randf_range(0, W), rng.randf_range(BASE_Y, H - 2), rng.randf_range(1.0, 2.5), rng.randf_range(1.0, 1.8), pebble)


## An enemy banner planted on the wall.
func _banner(img: Image, x: int, top: int) -> void:
	var pole := Color8(64, 46, 34)
	for y in range(top - 46, top + 2):
		img.set_pixel(x, y, pole)
		img.set_pixel(x + 1, y, pole.lightened(0.15))
	var red := Color8(178, 36, 36)
	for y in range(top - 44, top - 20):
		var wave := int(2.0 * sin(float(y) * 0.35))
		for i in range(2, 24 + wave):
			var c := red if i < 22 + wave else red.darkened(0.35)
			if y == top - 44 or y == top - 21:
				c = red.darkened(0.3)
			img.set_pixel(x + i, y, c)
	for y in range(top - 37, top - 28):       # a dark emblem
		for i in range(10, 16):
			img.set_pixel(x + i, y, Color8(70, 20, 22))


func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	for y in range(int(cy - ry), int(cy + ry) + 1):
		for x in range(int(cx - rx), int(cx + rx) + 1):
			if x < 0 or y < 0 or x >= W or y >= H:
				continue
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, img.get_pixel(x, y).blend(col))


func _save(img: Image, key: String) -> void:
	img.save_png(ProjectSettings.globalize_path(OUT + key + ".png"))
	print("saved ", key)
