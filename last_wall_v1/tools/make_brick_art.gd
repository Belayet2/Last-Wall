extends SceneTree
## Turns the downloaded brick texture packs into the game's brick sprites (64 x 22 each).
## Run from the project folder:
##   godot --headless --path . --script res://tools/make_brick_art.gd -- --src=<folder with the unzipped packs>
## The folder is searched (with subfolders) for the texture file names below.
## The packs themselves stay outside the project (their license does not allow sharing the raw textures).
##
## Makes:
##   brick_mud / brick_clay / brick_stone / brick_marble  = bricks you buy in the shop
##   foundation_1 .. foundation_5                          = the pre-built bottom row of each wall
##   brick_cracks_1 / brick_cracks_2                       = cracks drawn over damaged bricks
##   brick_slot                                            = empty place where a brick can go (build screen)

const OUT := "res://assets/sprites/"
const ArtData = preload("res://scripts/data/art_data.gd")
const W := 64
const H := 22

## name -> [texture file, crop scale (texture px per sprite px), tint]
## scale 0 = find the brightest flat spot at 1:1 (for tile textures with dark grout lines)
const SOURCES := {
	"brick_mud": ["oldbrick_faded_s42.png", 2, Color(1.3, 1.12, 0.78)],
	"brick_clay": ["brick_red_s42.png", 2, Color(1, 1, 1)],
	"brick_stone": ["brick_gray_s42.png", 2, Color(1, 1, 1)],
	"brick_marble": ["paintedbrick_white_s42.png", 0, Color(1.04, 1.03, 1.0)],
	"foundation_1": ["paintedbrick_real_s630_seamless.png", 5, Color(1, 1, 1)],
	"foundation_2": ["oldbrick_real_s648_seamless.png", 5, Color(1, 1, 1)],
	"foundation_3": ["brick_real_s408_seamless.png", 5, Color(1, 1, 1)],
	"foundation_4": ["oldbrick_styl_s748_seamless.png", 5, Color(0.92, 1.0, 0.9)],
	"foundation_5": ["paintedbrick_styl_s730_seamless.png", 5, Color(0.74, 0.84, 0.95)],
}

var _files := {}


func _initialize() -> void:
	var src := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--src="):
			src = arg.substr(6)
	if src != "":
		_scan(src)
		for key in SOURCES:
			var spec: Array = SOURCES[key]
			if not _files.has(spec[0]):
				push_warning("Not found: " + spec[0] + " (skipping " + key + ")")
				continue
			var img := _crop(Image.load_from_file(_files[spec[0]]), int(spec[1]))
			_tint(img, spec[2])
			_bevel(img, key.begins_with("foundation"))
			_save(img, key)
	else:
		print("No --src given: only the cracks and the slot are made.")
	_save(_cracks(1), "brick_cracks_1")
	_save(_cracks(2), "brick_cracks_2")
	_save(_slot(), "brick_slot")
	quit()


func _scan(dir_path: String) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		push_error("Can't open " + dir_path)
		return
	for f in d.get_files():
		_files[f] = dir_path.path_join(f)
	for sub in d.get_directories():
		_scan(dir_path.path_join(sub))


## Cuts a W x H brick out of the texture.
func _crop(src: Image, scale: int) -> Image:
	src.convert(Image.FORMAT_RGBA8)
	if scale > 0:
		var region := src.get_region(Rect2i(37, 53, W * scale, H * scale))
		region.resize(W, H, Image.INTERPOLATE_LANCZOS)
		return region
	# tile texture: find the flattest bright spot (a block face without grout lines)
	var best := Vector2i.ZERO
	var best_score := -1.0
	for y in range(0, src.get_height() - H, 6):
		for x in range(0, src.get_width() - W, 6):
			var darkest := 1.0
			var brightest := 0.0
			var total := 0.0
			var n := 0
			for sy in range(0, H, 3):
				for sx in range(0, W, 3):
					var v := src.get_pixel(x + sx, y + sy).get_luminance()
					darkest = minf(darkest, v)
					brightest = maxf(brightest, v)
					total += v
					n += 1
			var score := total / n - (brightest - darkest) * 2.0
			if score > best_score:
				best_score = score
				best = Vector2i(x, y)
	return src.get_region(Rect2i(best, Vector2i(W, H)))


func _tint(img: Image, tint: Color) -> void:
	if tint == Color(1, 1, 1):
		return
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(minf(c.r * tint.r, 1.0), minf(c.g * tint.g, 1.0), minf(c.b * tint.b, 1.0), c.a))


## Dark outline, light top-left edge, shadowed bottom-right edge, cut corners.
func _bevel(img: Image, heavy: bool) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			var edge_x := mini(x, w - 1 - x)
			var edge_y := mini(y, h - 1 - y)
			if edge_x == 0 and edge_y == 0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))            # rounded corner
			elif edge_x == 0 or edge_y == 0:
				img.set_pixel(x, y, c.darkened(0.6))               # outline
			elif y == 1 or x == 1:
				img.set_pixel(x, y, c.lightened(0.28))             # light from the top-left
			elif y == h - 2 or x == w - 2:
				img.set_pixel(x, y, c.darkened(0.3))
			elif heavy and (y == h - 3):
				img.set_pixel(x, y, c.darkened(0.15))


## Transparent picture with crack lines (stage 1 = light, 2 = badly cracked).
func _cracks(stage: int) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ink := Color(0.16, 0.11, 0.08, 0.9)
	var lines := [[Vector2i(22, 1), Vector2i(27, 8), Vector2i(24, 13), Vector2i(30, 20)]]
	if stage >= 2:
		lines.append([Vector2i(46, 1), Vector2i(42, 7), Vector2i(48, 12), Vector2i(44, 20)])
		lines.append([Vector2i(27, 8), Vector2i(36, 10), Vector2i(42, 7)])
		lines.append([Vector2i(2, 14), Vector2i(10, 12), Vector2i(14, 17)])
	for line in lines:
		for i in range(line.size() - 1):
			_line(img, line[i], line[i + 1], ink)
	if stage >= 2:   # a chipped corner
		for y in range(1, 6):
			for x in range(W - 8 + y, W - 1):
				img.set_pixel(x, y, Color(0.12, 0.08, 0.06, 0.75))
	return img


func _slot() -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0.1))
	var dash := Color(1, 0.97, 0.85, 0.85)
	for x in range(1, W - 1):
		if (x / 4) % 2 == 0:
			img.set_pixel(x, 1, dash)
			img.set_pixel(x, H - 2, dash)
	for y in range(1, H - 1):
		if (y / 4) % 2 == 0:
			img.set_pixel(1, y, dash)
			img.set_pixel(W - 2, y, dash)
	return img


func _line(img: Image, a: Vector2i, b: Vector2i, c: Color) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in range(steps + 1):
		var p := Vector2(a).lerp(Vector2(b), float(i) / maxf(steps, 1))
		var x := int(round(p.x))
		var y := int(round(p.y))
		if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
			img.set_pixel(x, y, c)


func _save(img: Image, key: String) -> void:
	var path := ProjectSettings.globalize_path(_path_of(key))
	img.save_png(path)
	print("saved ", key)

## Where a picture lives (its path in scripts/data/art_data.gd); makes the folder if needed.
func _path_of(key: String) -> String:
	var path := OUT + key + ".png"
	if ArtData.SPRITES.has(key):
		path = ArtData.SPRITES[key]["path"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	return path
