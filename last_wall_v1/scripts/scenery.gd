## Scenery built from the game's own pictures, so everything looks like the same world:
##   - brick walls of any size, from the brick pictures (the side walls, the enemy side, the story)
##   - sky, clouds, sea and banners for the story scenes
## Bricks are redrawn sharp at the size asked for (with their own dark outline), and kept in a cache.
## Replace a brick picture and every wall drawn from it changes with it.

const ArtData = preload("res://scripts/data/art_data.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const BrickData = preload("res://scripts/data/brick_data.gd")

const SKY_TOP := Color8(108, 174, 236)
const SKY_LOW := Color8(190, 222, 246)
const ENEMY_RED := Color8(176, 38, 36)
const KINGDOM_BLUE := Color8(40, 84, 176)
const GOLD := Color8(240, 192, 64)

static var _textures := {}


# ---------------------------------------------------------------- bricks

## The brick picture `art` redrawn at `size`.
## part: 0 = whole brick, 1 = left half, 2 = right half (for walls with shifted rows).
## fade: 0..1 fades it toward the sky (far away walls).
static func brick(art: String, size: Vector2i, part: int = 0, fade: float = 0.0) -> Texture2D:
	var key := "%s|%d|%d|%d|%.2f" % [art, size.x, size.y, part, fade]
	if _textures.has(key):
		return _textures[key]
	var source := ArtData.texture(art)
	var native := Vector2i(ArtData.size_of(art))
	if size == native and part == 0 and fade == 0.0 and Vector2i(source.get_size()) == native:
		_textures[key] = source
		return source
	var img := _image_of(source)
	if part > 0:
		var half := int(img.get_width() * 0.5)
		img = img.get_region(Rect2i(0 if part == 1 else img.get_width() - half, 0, half, img.get_height()))
	if img.get_size() != size:
		img.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	_outline(img, fade)
	var tex := ImageTexture.create_from_image(img)
	_textures[key] = tex
	return tex


## Crack lines (stage 1 or 2) for a brick of `size`.
static func cracks(stage: int, size: Vector2i) -> Texture2D:
	var key := "cracks|%d|%d|%d" % [stage, size.x, size.y]
	if _textures.has(key):
		return _textures[key]
	var img := _image_of(ArtData.texture("brick_cracks_%d" % stage))
	img.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	var tex := ImageTexture.create_from_image(img)
	_textures[key] = tex
	return tex


## A wall drawn from a map: one string per row, TOP row first.
##   "#" brick   "." no brick   "1" / "2" cracked brick
## bond "stack": bricks in straight columns (like our wall).
## bond "running": every other row (counted from the bottom) starts with half a brick, like real masonry.
##                 Those rows have one more place in the map (a half brick at each end).
static func wall(rows: Array, art: String, size: Vector2i, bond: String = "stack", fade: float = 0.0) -> Node2D:
	var node := Node2D.new()
	var count := rows.size()
	for r in range(count):
		var line: String = rows[r]
		var shifted := bond == "running" and (count - 1 - r) % 2 == 1
		var x := 0
		for c in range(line.length()):
			var ch := line[c]
			var part := 0
			var w := size.x
			if shifted and c == 0:
				part = 2
				w = int(size.x * 0.5)
			elif shifted and c == line.length() - 1:
				part = 1
				w = int(size.x * 0.5)
			if ch != ".":
				var s := Sprite2D.new()
				s.centered = false
				s.texture = brick(art, Vector2i(w, size.y), part, fade)
				s.position = Vector2(x, r * size.y)
				node.add_child(s)
				if ch == "1" or ch == "2":
					var crack := Sprite2D.new()
					crack.centered = false
					crack.texture = cracks(int(ch), Vector2i(w, size.y))
					s.add_child(crack)
			x += w
	return node


## One of the two side walls of the field (left or right): one brick wide, from the top of the
## screen to the bottom, laid like real masonry. It uses the current wall's own bricks.
static func side_wall(art: String, right: bool) -> Node2D:
	var size := Vector2i(int(BrickData.COLUMN_LEFT), int(BrickData.BRICK_H))
	var rows := []
	var count := ceili(GameData.SCREEN_HEIGHT / size.y) + 1
	for r in range(count):
		rows.append("#" if (count - 1 - r) % 2 == 0 else "##")
	var node := wall(rows, art, size, "running")
	node.position = Vector2(GameData.SCREEN_WIDTH - size.x if right else 0.0, GameData.SCREEN_HEIGHT - count * size.y)
	node.modulate = Color(0.86, 0.86, 0.88)
	# a soft shadow on the field side, so it reads as a wall standing up
	var shade := TextureRect.new()
	shade.texture = _gradient(Color(0, 0, 0, 0.32), Color(0, 0, 0, 0.0), right)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.size = Vector2(12, count * size.y)
	shade.position = Vector2(-12.0 if right else float(size.x), 0)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(shade)
	var edge := ColorRect.new()
	edge.color = Color(0.2, 0.15, 0.12, 0.6)
	edge.size = Vector2(2, count * size.y)
	edge.position = Vector2(0.0 if right else float(size.x - 2), 0)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(edge)
	return node


## The enemy side: the next wall out, held by the enemy, seen from far away (smaller bricks).
## Built like our wall (a last layer + 3 rows, battlements on top) and broken the way ours breaks:
## whole bricks knocked out, cracked bricks around the holes, one breach right through the last layer.
## `seed` picks where the damage is (the same every time for the same wall).
## `avoid` = x positions where enemies stand (the breach goes between them, where you can see it).
static func enemy_wall(art: String, seed: int, avoid: Array = []) -> Node2D:
	var size := Vector2i(48, 16)
	var cols := int((GameData.SCREEN_WIDTH - 2.0 * BrickData.COLUMN_LEFT) / size.x)
	var rows := 5                                    # battlements + 3 rows + the last layer
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var grid := []                                   # grid[row][col] = "#", "." or crack "1"/"2"
	for r in range(rows):
		var line := []
		for c in range(cols):
			line.append("#" if r > 0 or c % 2 == 0 else ".")
		grid.append(line)
	# the breach: down through the last layer, widening toward the top
	var b := rng.randi_range(4, cols - 6)
	for attempt in range(40):
		var mid := BrickData.COLUMN_LEFT + (b + 1) * size.x
		var clear := true
		for x in avoid:
			if absf(float(x) - mid) < 110.0:
				clear = false
		if clear:
			break
		b = rng.randi_range(3, cols - 5)
	for r in range(rows):
		for c in range(b - 2, b + 4):
			var away := 0 if (c == b or c == b + 1) else (1 if (c == b - 1 or c == b + 2) else 2)
			if r < rows - away * 2 and c >= 0 and c < cols:
				grid[r][c] = "."
	# impact holes, like stones knocked them out
	var shapes := [[Vector2i(0, 0)], [Vector2i(0, 0), Vector2i(1, 0)], [Vector2i(0, 0), Vector2i(0, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]]
	for i in range(rng.randi_range(6, 8)):
		var at := Vector2i(rng.randi_range(0, cols - 2), rng.randi_range(1, rows - 2))
		if absi(at.x - b) < 4:
			continue
		for p in shapes[rng.randi_range(0, shapes.size() - 1)]:
			var q: Vector2i = at + p
			if q.y < rows - 1 and q.x < cols:
				grid[q.y][q.x] = "."
	for c in range(cols):                            # knocked-off battlements
		if grid[0][c] == "#" and rng.randf() < 0.15:
			grid[0][c] = "."
	# bricks next to a hole are cracked
	for r in range(rows):
		for c in range(cols):
			if grid[r][c] != "#":
				continue
			var near_hole := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(c, r) + d
				if q.x >= 0 and q.x < cols and q.y > 0 and q.y < rows and grid[q.y][q.x] == ".":
					near_hole = true
			if near_hole and rng.randf() < 0.7:
				grid[r][c] = "2" if rng.randf() < 0.35 else "1"
	var lines := []
	for r in range(rows):
		lines.append("".join(PackedStringArray(grid[r])))
	var node := Node2D.new()
	var bricks := wall(lines, art, size)
	node.add_child(bricks)
	var top := 140.0 - rows * size.y
	bricks.position = Vector2(BrickData.COLUMN_LEFT, top)
	# shadow at the foot of the wall
	var shadow := TextureRect.new()
	shadow.texture = _gradient(Color(0, 0, 0, 0.28), Color(0, 0, 0, 0), false, true)
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	shadow.position = Vector2(0, 140)
	shadow.size = Vector2(GameData.SCREEN_WIDTH, 12)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(shadow)
	# broken pieces of the bricks that fell out lie in front of the breach
	var piece := Vector2i(int(size.x * 0.5), int(size.y * 0.75))
	for i in range(7):
		var loose := Sprite2D.new()
		loose.texture = brick(art, piece, 1 + i % 2)
		loose.position = Vector2(BrickData.COLUMN_LEFT + (b + 1) * size.x + rng.randf_range(-56, 56), rng.randf_range(139, 147))
		loose.rotation = rng.randf_range(-0.25, 0.25)
		node.add_child(loose)
	# enemy banners hang on the standing parts
	var hung := 0
	var fifth := int(cols / 5.0)
	for c in [fifth, cols - 1 - fifth, int(cols / 2.0)]:
		var col: int = c
		if hung >= 2 or absi(col - b) < 4:
			continue
		var fl := banner(ENEMY_RED, Vector2(22, 38), Color8(60, 18, 20))
		fl.position = Vector2(BrickData.COLUMN_LEFT + col * size.x + size.x * 0.5, top + size.y + 2)
		node.add_child(fl)
		hung += 1
	return node


# ---------------------------------------------------------------- story bits

## A hanging cloth banner (hangs down from its top middle), gently swaying.
static func banner(color: Color, size: Vector2, emblem: Color, sway: bool = true) -> Node2D:
	var node := Node2D.new()
	var w := size.x * 0.5
	var cloth := Polygon2D.new()
	cloth.polygon = PackedVector2Array([Vector2(-w, 0), Vector2(w, 0), Vector2(w, size.y), Vector2(0, size.y - 8), Vector2(-w, size.y)])
	cloth.color = color
	node.add_child(cloth)
	var hem := Line2D.new()
	hem.points = PackedVector2Array([Vector2(-w, size.y), Vector2(-w, 0), Vector2(w, 0), Vector2(w, size.y), Vector2(0, size.y - 8), Vector2(-w, size.y)])
	hem.width = 2.0
	hem.default_color = color.darkened(0.4)
	node.add_child(hem)
	var mark := Polygon2D.new()
	var r := minf(size.x, size.y) * 0.22
	var pts := PackedVector2Array()
	for i in range(12):
		pts.append(Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0)) * r + Vector2(0, size.y * 0.42))
	mark.polygon = pts
	mark.color = emblem
	node.add_child(mark)
	var rod := Line2D.new()
	rod.points = PackedVector2Array([Vector2(-w - 3, 0), Vector2(w + 3, 0)])
	rod.width = 3.0
	rod.default_color = Color8(70, 50, 36)
	node.add_child(rod)
	if sway:   # tweens can only start once the banner is in the scene
		var speed := randf_range(1.1, 1.6)
		node.ready.connect(func() -> void:
			var t := node.create_tween().set_loops()
			t.tween_property(cloth, "skew", 0.06, speed).set_trans(Tween.TRANS_SINE)
			t.parallel().tween_property(mark, "skew", 0.06, speed).set_trans(Tween.TRANS_SINE)
			t.tween_property(cloth, "skew", -0.06, speed).set_trans(Tween.TRANS_SINE)
			t.parallel().tween_property(mark, "skew", -0.06, speed).set_trans(Tween.TRANS_SINE))
	return node


## A flag on a pole (the pole's foot is at 0,0).
static func flag(color: Color, height: float = 46.0, emblem: Color = Color(0, 0, 0, 0)) -> Node2D:
	var node := Node2D.new()
	var pole := Line2D.new()
	pole.points = PackedVector2Array([Vector2.ZERO, Vector2(0, -height)])
	pole.width = 3.0
	pole.default_color = Color8(70, 50, 36)
	node.add_child(pole)
	var cloth := Polygon2D.new()
	cloth.polygon = PackedVector2Array([Vector2(1, -height), Vector2(28, -height + 3), Vector2(24, -height + 10), Vector2(29, -height + 17), Vector2(1, -height + 18)])
	cloth.color = color
	node.add_child(cloth)
	if emblem.a > 0.0:
		var dot := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in range(10):
			pts.append(Vector2(cos(TAU * i / 10.0), sin(TAU * i / 10.0)) * 4.0 + Vector2(12, -height + 9))
		dot.polygon = pts
		dot.color = emblem
		node.add_child(dot)
	node.ready.connect(func() -> void:
		var t := node.create_tween().set_loops()
		t.tween_property(cloth, "skew", 0.12, 0.6).set_trans(Tween.TRANS_SINE)
		t.tween_property(cloth, "skew", -0.05, 0.6).set_trans(Tween.TRANS_SINE))
	return node


## A filled rectangle with a vertical color fade (sky, sea, ground).
static func gradient_rect(rect: Rect2, top: Color, bottom: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	p.vertex_colors = PackedColorArray([top, top, bottom, bottom])
	return p


## A soft cloud made of puffs. Drifts slowly to the right if `drift` > 0 (pixels per second).
static func cloud(width: float, drift: float = 0.0) -> Node2D:
	var node := Node2D.new()
	var puffs := 5
	for i in range(puffs):
		var r := width * randf_range(0.16, 0.24)
		var c := Vector2((i - (puffs - 1) * 0.5) * width * 0.17, randf_range(-r * 0.3, r * 0.15))
		node.add_child(_ellipse(c + Vector2(0, 3), Vector2(r, r * 0.62), Color(0.75, 0.84, 0.95, 0.45)))
		node.add_child(_ellipse(c, Vector2(r, r * 0.62), Color(1, 1, 1, 0.85)))
	if drift > 0.0:
		node.set_meta("drift", drift)
	return node


## Moves every cloud that has a "drift" speed; call from _process. Clouds wrap around the screen.
static func drift_clouds(parent: Node, delta: float) -> void:
	for child in parent.get_children():
		if child is Node2D and child.has_meta("drift"):
			var n := child as Node2D
			n.position.x += float(n.get_meta("drift")) * delta
			if n.position.x > GameData.SCREEN_WIDTH + 160.0:
				n.position.x = -160.0


static func _ellipse(center: Vector2, radius: Vector2, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(20):
		var a := TAU * i / 20.0
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	p.polygon = pts
	p.color = color
	return p


# ---------------------------------------------------------------- helpers

static func _image_of(tex: Texture2D) -> Image:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


## Dark outline, light top edge, shadowed bottom-right edge, cut corners (like the brick pictures).
static func _outline(img: Image, fade: float) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			if fade > 0.0:
				c = Color(c.lerp(SKY_LOW, fade), c.a)
			var ex := mini(x, w - 1 - x)
			var ey := mini(y, h - 1 - y)
			if ex == 0 and ey == 0:
				c = Color(0, 0, 0, 0)
			elif ex == 0 or ey == 0:
				c = Color(c.darkened(0.55), 1.0)
			elif y == 1:
				c = c.lightened(0.2)
			elif y == h - 2 or x == w - 2:
				c = c.darkened(0.25)
			img.set_pixel(x, y, c)


## A small gradient picture: across (left to right) or down (top to bottom).
static func _gradient(from: Color, to: Color, flip: bool, down: bool = false) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([to, from] if flip else [from, to])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 16
	t.height = 16
	t.fill_from = Vector2.ZERO
	t.fill_to = Vector2(0, 1) if down else Vector2(1, 0)
	return t
