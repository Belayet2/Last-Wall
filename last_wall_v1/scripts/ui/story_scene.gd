extends Node2D
## One animated story scene, drawn from the game's own pictures: the brick walls, the ship, the cannon,
## the hero and his shield, the king. Things happen when the narrator's text reaches a word ("cues"),
## so the picture follows the story. If the player shows the whole text at once, every cue left happens at once.
## Scenes (see story_data.gd): walls_rise, kings, war, sails, walls_fall, king_calls, hero.
## Everything important is kept in the top part of the screen: the text box covers the bottom.

const ArtData = preload("res://scripts/data/art_data.gd")
const GameData = preload("res://scripts/data/game_data.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const BrickData = preload("res://scripts/data/brick_data.gd")
const FxData = preload("res://scripts/data/fx_data.gd")
const Scenery = preload("res://scripts/scenery.gd")
const FxScript = preload("res://scripts/fx.gd")
const UI = preload("res://scripts/ui/ui_style.gd")

const W := 1280.0
const H := 720.0
const LAND_Y := 350.0                    # panorama: the top of the land
const SHORE_X := 300.0                   # panorama: where the sea ends
const PANO_BRICK := Vector2i(32, 11)     # panorama bricks (far away)
## The panorama's five walls, from the sea inland: which wall (1 = the Last Wall), where, how big.
const PANO_WALLS := [
	{"wall": 5, "x": 400.0, "cols": 3, "rows": 8},
	{"wall": 4, "x": 565.0, "cols": 3, "rows": 9},
	{"wall": 3, "x": 730.0, "cols": 3, "rows": 10},
	{"wall": 2, "x": 895.0, "cols": 3, "rows": 11},
	{"wall": 1, "x": 1075.0, "cols": 4, "rows": 14},
]
const SUNSET_TOP := Color8(236, 150, 120)
const SUNSET_LOW := Color8(255, 214, 160)

var kind := ""
var text := ""

var _cues: Array = []
var _clouds: Node2D
var _sky: Polygon2D
var _walls: Array = []          # panorama: one Node2D per wall (0 = Zoa's, by the sea)
var _towns: Array = []          # panorama: the houses that appear when each wall is built
var _plaques: Array = []        # panorama: name plates under the walls
var _ships: Array = []
var _defenders: Array = []      # war: soldiers on the wall
var _war_flag: Node2D
var _volley: Timer
var _shield: Sprite2D           # king_calls
var _aura: Node2D               # king_calls / hero: the golden arcs
var _beam: Polygon2D            # king_calls: the light on the shield
var _sparkles: CPUParticles2D
var _cannons: Array = []        # hero: [{"sprite", "muzzle", "home"}]
var _next_cannon := 0
var _hero_aura: Line2D
var _hero_glow: Line2D
var _sea_index := -1            # where the sea's waves are in the drawing order (ships go just above)


func setup(scene_kind: String, slide_text: String) -> void:
	kind = scene_kind
	text = slide_text


func _ready() -> void:
	match kind:
		"walls_rise":
			_scene_walls_rise()
		"kings":
			_scene_kings()
		"war":
			_scene_war()
		"sails":
			_scene_sails()
		"walls_fall":
			_scene_walls_fall()
		"king_calls":
			_scene_king_calls()
		"hero":
			_scene_hero()
		_:
			push_warning("Unknown story scene: " + kind)
			_sky_and_clouds(H)


func _process(delta: float) -> void:
	if _clouds:
		Scenery.drift_clouds(_clouds, delta)


## Run `action` when the text reaches `word` (or at `fallback`, 0..1 of the text, if the word is not in it).
func cue(word: String, fallback: float, action: Callable) -> void:
	var at := text.findn(word)
	if at < 0:
		at = int(text.length() * fallback)
	_cues.append({"at": at, "action": action, "done": false})


## The story calls this every frame with how many letters of the text are showing.
func reveal(chars: int) -> void:
	for c in _cues:
		if not c["done"] and int(c["at"]) <= chars:
			c["done"] = true
			(c["action"] as Callable).call()


# ================================================================ the scenes

## 1. Five kings build five walls, from the shore inland. The town grows behind them.
func _scene_walls_rise() -> void:
	_panorama(false)
	var words := ["King Zoa", "second wall", "generation after", "five kings", "the fifth"]
	var spots := [0.04, 0.3, 0.45, 0.65, 0.85]
	for i in range(PANO_WALLS.size()):
		var n := i
		cue(words[i], spots[i], func() -> void: _raise_wall(n))


## 2. The kings' names under their walls. Zoa's is loved, Aldren's is the strongest: the Last Wall.
func _scene_kings() -> void:
	_panorama(true)
	for i in range(PANO_WALLS.size()):
		var n := i
		var who := _king_name(i)
		cue(who, 0.04 + 0.06 * i, func() -> void: _plaque(n, true))
	cue("loved", 0.4, func() -> void:
		_glow(0)
		_note(0, "the first wall"))
	cue("strongest", 0.6, func() -> void:
		_glow(4)
		_note(4, "the strongest"))
	cue("Last Wall", 0.7, _last_wall_title)


## 3. Raiders from the sea. We bounce their cannonballs back and win... but most soldiers never come home.
func _scene_war() -> void:
	var land := 360.0
	_sky_and_clouds(land + 20.0)
	_sea(Rect2(0, land + 8.0, 700.0, H - land))
	_land(660.0, land)
	# Zoa's wall on the shore, with our soldiers on top
	var art: String = LevelData.WALLS[4]["foundation"]
	var rows := 10
	var wall := _slab(art, 5, rows)
	var wall_x := 790.0
	wall.position = Vector2(wall_x - 80.0, land - (rows + 1) * PANO_BRICK.y)
	var walk := wall.position.y + PANO_BRICK.y       # where the soldiers stand (behind the battlements)
	for x in [735.0, 792.0, 848.0]:
		var s := _soldier(0.42)
		s.position = Vector2(x, walk + 2.0)
		add_child(s)
		_defenders.append(s)
	add_child(wall)
	_war_flag = Scenery.flag(Scenery.KINGDOM_BLUE, 54.0, Scenery.GOLD)
	_war_flag.position = Vector2(wall_x + 64.0, wall.position.y)
	add_child(_war_flag)
	for x in [120.0, 320.0, 520.0]:
		var ship := _ship(0.55, Vector2(x - 700.0, land + 14.0))
		ship.set_meta("x", x)
		_ships.append(ship)
	_volley = Timer.new()
	_volley.wait_time = 0.75
	_volley.timeout.connect(_war_shot)
	add_child(_volley)
	cue("raiders", 0.05, func() -> void:
		for ship in _ships:
			var sh := ship as Node2D
			sh.create_tween().tween_property(sh, "position:x", float(sh.get_meta("x")), 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
	cue("fought", 0.3, func() -> void:
		_volley.start()
		_war_shot())
	cue("we won", 0.5, _war_won)
	cue("price", 0.65, _war_price)
	cue("never came home", 0.85, _war_graves)


## 4. From the wall: sails on the horizon. More and more of them.
func _scene_sails() -> void:
	var horizon := 300.0
	_sky_and_clouds(horizon + 2.0, Scenery.SKY_TOP, Color8(214, 232, 244))
	_sea(Rect2(0, horizon, W, H - horizon), Color8(150, 200, 228), Color8(36, 104, 176))
	var slots := []
	for i in range(22):
		slots.append(70.0 + i * 52.0)
	slots.shuffle()
	var watchman := _soldier(1.1)
	watchman.position = Vector2(608.0, 452.0)
	add_child(watchman)
	# the top of Zoa's wall, right in front of us (big bricks)
	var art: String = LevelData.WALLS[4]["foundation"]
	var cols := int(W / BrickData.BRICK_W)
	var merlons := ""
	var row := ""
	for c in range(cols):
		merlons += "#" if c % 2 == 0 else "."
		row += "#"
	var parapet := Scenery.wall([merlons, row, row, row, row], art, Vector2i(int(BrickData.BRICK_W), int(BrickData.BRICK_H)))
	parapet.position = Vector2(0, 392.0)
	add_child(parapet)
	var fl := Scenery.flag(Scenery.KINGDOM_BLUE, 70.0, Scenery.GOLD)
	fl.position = Vector2(16 * BrickData.BRICK_W + 30.0, 392.0)
	add_child(fl)
	var counts := [["sails on the horizon", 0.2, 3], ["More ships", 0.45, 5], ["Many more", 0.6, 9], ["no army", 0.8, 4]]
	for spec in counts:
		var n: int = spec[2]
		cue(spec[0], spec[1], func() -> void:
			for k in range(n):
				var x: float = slots.pop_back() if not slots.is_empty() else randf_range(60.0, W - 60.0)
				_far_ship(Vector2(x + randf_range(-12, 12), horizon + randf_range(4, 30)), k * 0.18))


## 5. The walls fall, one by one from the sea, down to their last layer. Only the Last Wall stands.
func _scene_walls_fall() -> void:
	_panorama(true)
	for i in range(PANO_WALLS.size()):
		_plaque(i, false)
	for spec in [[70.0, 0.42, LAND_Y + 18.0], [205.0, 0.42, LAND_Y + 22.0]]:
		_ships.append(_ship(spec[1], Vector2(float(spec[0]) - 90.0, float(spec[2]))))
	cue(_king_name(0), 0.04, func() -> void:
		var shift := 90.0
		for ship in _ships:
			var sh := ship as Node2D
			sh.create_tween().tween_property(sh, "position:x", sh.position.x + shift, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_fall(0))
	cue(_king_name(1), 0.25, func() -> void: _fall(1))
	cue(_king_name(2), 0.4, func() -> void: _fall(2))
	cue("within a week", 0.6, func() -> void: _fall(3))
	cue("except", 0.8, func() -> void:
		_glow(4)
		_last_wall_title())


## 6. The throne room: the old king, and the mythical shield. "Call the hero."
func _scene_king_calls() -> void:
	var floor_y := 470.0
	# the hall is built of the Last Wall's white stone
	var art: String = LevelData.WALLS[0]["foundation"]
	var size := Vector2i(int(BrickData.BRICK_W), int(BrickData.BRICK_H))
	var lines := []
	var count := int(floor_y / size.y) + 1
	for r in range(count):
		lines.append("####################" if (count - 1 - r) % 2 == 0 else "#####################")
	var hall := Scenery.wall(lines, art, size, "running")
	hall.position = Vector2(0, floor_y - count * size.y)
	hall.modulate = Color(0.84, 0.84, 0.9)
	add_child(hall)
	add_child(Scenery.gradient_rect(Rect2(0, floor_y, W, H - floor_y), Color8(226, 208, 172), Color8(176, 152, 120)))
	add_child(Scenery.gradient_rect(Rect2(0, floor_y - 6, W, 6), Color8(120, 100, 80), Color8(160, 140, 112)))
	_window(Rect2(90, 70, 120, 250))
	_window(Rect2(1070, 70, 120, 250))
	add_child(_poly([Vector2(90, 320), Vector2(210, 320), Vector2(560, floor_y + 60), Vector2(280, floor_y + 60)], Color(1, 0.98, 0.85, 0.1)))
	_beam = _poly([Vector2(1070, 320), Vector2(1190, 320), Vector2(1010, floor_y + 60), Vector2(800, floor_y + 60)], Color(1, 0.96, 0.8, 0.1))
	add_child(_beam)
	for x in [300.0, 640.0]:
		var b := Scenery.banner(Scenery.KINGDOM_BLUE, Vector2(64, 170), Scenery.GOLD)
		b.position = Vector2(x, 40)
		add_child(b)
	# the throne, the king, the armrests in front of him
	add_child(_poly([Vector2(380, 446), Vector2(380, 170), Vector2(410, 122), Vector2(470, 92), Vector2(530, 122), Vector2(560, 170), Vector2(560, 446)], Color8(40, 70, 156)))
	add_child(_outline([Vector2(380, 446), Vector2(380, 170), Vector2(410, 122), Vector2(470, 92), Vector2(530, 122), Vector2(560, 170), Vector2(560, 446)], Scenery.GOLD, 7.0))
	add_child(_circle(Vector2(470, 104), 9.0, Scenery.GOLD))
	var king := ArtData.make_sprite("portrait_king", Vector2(192, 224))
	king.position = Vector2(470, 300)
	add_child(king)
	add_child(_poly([Vector2(396, 398), Vector2(544, 398), Vector2(548, 446), Vector2(392, 446)], Color8(48, 82, 170)))
	add_child(_outline([Vector2(396, 398), Vector2(544, 398), Vector2(548, 446), Vector2(392, 446), Vector2(396, 398)], Scenery.GOLD, 4.0))
	for x in [366.0, 536.0]:
		add_child(_poly([Vector2(x, 352), Vector2(x + 38, 352), Vector2(x + 38, 446), Vector2(x, 446)], Color8(204, 160, 52)))
		add_child(_poly([Vector2(x - 4, 344), Vector2(x + 42, 344), Vector2(x + 42, 356), Vector2(x - 4, 356)], Color8(236, 196, 82)))
	add_child(_poly([Vector2(340, 446), Vector2(600, 446), Vector2(620, floor_y + 10), Vector2(320, floor_y + 10)], Color8(196, 180, 150)))
	# the mythical shield on its stand (white stone, like the Last Wall)
	var stand := Scenery.wall(["##", "##", "##"], art, size)
	stand.position = Vector2(836, floor_y - 3 * size.y)
	add_child(stand)
	add_child(_poly([Vector2(826, floor_y - 3 * size.y - 8), Vector2(974, floor_y - 3 * size.y - 8), Vector2(974, floor_y - 3 * size.y), Vector2(826, floor_y - 3 * size.y)], Color8(214, 206, 190)))
	_shield = ArtData.make_sprite("shield", Vector2(176, 144))
	_shield.position = Vector2(900, 316)
	_shield.modulate = Color(0.7, 0.7, 0.76)
	add_child(_shield)
	_aura = _arcs(Vector2(900, 300), 120.0, 74.0, 1.0)
	_aura.modulate.a = 0.0
	add_child(_aura)
	cue("one soldier", 0.55, func() -> void:
		_beam.create_tween().tween_property(_beam, "color:a", 0.24, 1.0))
	cue("mythical shield", 0.7, _awaken_shield)
	cue("Call the hero", 0.9, _speech)


## 7. The hero on the Last Wall: a cannonball comes, his shield bounces it straight back. Again and again.
func _scene_hero() -> void:
	var sky := ArtData.make_sprite("sky")
	sky.position = Vector2(W * 0.5, 75)
	add_child(sky)
	var stands := [352.0, 640.0, 928.0]
	add_child(Scenery.enemy_wall(LevelData.WALLS[0]["far_wall"], 7037, stands))
	var ground := ArtData.make_sprite("ground", Vector2(W, 280))
	ground.position = Vector2(W * 0.5, 150 + 140)
	add_child(ground)
	var path := ArtData.make_sprite("path", Vector2(W, 60))
	path.position = Vector2(W * 0.5, 460)
	add_child(path)
	for x in stands:
		var c := ArtData.make_sprite("enemy_cannon")
		c.position = Vector2(x, GameData.ENEMY_Y)
		c.flip_h = x > GameData.FIELD_CENTER_X
		c.offset = Vector2(-7 if c.flip_h else 7, 0)
		add_child(c)
		var face := -1.0 if c.flip_h else 1.0
		_cannons.append({"sprite": c, "muzzle": c.position + Vector2(36.0 * face, -4.0)})
	# the Last Wall, whole, and the side walls
	var art: String = LevelData.WALLS[0]["foundation"]
	var row := ""
	for c in range(BrickData.COLUMNS):
		row += "#"
	var last := Scenery.wall([row, row, row, row], art, Vector2i(int(BrickData.BRICK_W), int(BrickData.BRICK_H)))
	last.position = Vector2(BrickData.COLUMN_LEFT, 490)
	add_child(last)
	for right in [false, true]:
		add_child(Scenery.side_wall(art, right))
	# the hero, bigger than in the game
	var k := 1.4
	var feet := Vector2(640, 488)
	var shadow := ArtData.make_sprite("shadow", Vector2(70, 16) * k)
	shadow.position = feet + Vector2(0, -4)
	add_child(shadow)
	var shield := ArtData.make_sprite("shield")
	shield.scale *= k
	var body_center := feet - Vector2(0, 52.0 * k)
	shield.position = body_center + Vector2(0, GameData.SHIELD_CENTER_Y * k)
	add_child(shield)
	var aura := _arcs(shield.position, 70.0 * k, GameData.AURA_HEIGHT * k, 1.0)
	add_child(aura)
	_hero_glow = aura.get_child(0)
	_hero_aura = aura.get_child(1)
	var hero := ArtData.make_sprite("hero")
	hero.scale *= k
	hero.position = body_center
	add_child(hero)
	_aura = aura
	var loop := Timer.new()
	loop.wait_time = 2.1
	loop.timeout.connect(_hero_shot)
	add_child(loop)
	loop.start(0.6)
	cue("bounce it back", 0.8, func() -> void:
		var ring := _ring_wave(shield.position)
		add_child(ring))


# ================================================================ panorama (scenes 1, 2, 5)

func _panorama(built: bool) -> void:
	_sky_and_clouds(LAND_Y + 20.0)
	var hills := PackedVector2Array([Vector2(SHORE_X - 40.0, LAND_Y + 4.0)])
	for i in range(21):
		var x := SHORE_X - 40.0 + (W - SHORE_X + 40.0) * i / 20.0
		hills.append(Vector2(x, LAND_Y - 24.0 - sin(i * 0.9) * 10.0 - sin(i * 2.3) * 5.0))
	hills.append(Vector2(W, LAND_Y + 4.0))
	add_child(_poly(hills, Color8(176, 210, 198)))
	_sea(Rect2(0, LAND_Y + 6.0, SHORE_X + 30.0, H - LAND_Y))
	_land(SHORE_X, LAND_Y)
	for i in range(PANO_WALLS.size()):
		var info: Dictionary = PANO_WALLS[i]
		var town := _town(i)
		town.modulate.a = 1.0 if (built or i == 0) else 0.0      # Zoa's small town is there first
		_towns.append(town)
	for i in range(PANO_WALLS.size()):
		var info: Dictionary = PANO_WALLS[i]
		var cols: int = info["cols"]
		var rows: int = info["rows"]
		var level: Dictionary = LevelData.WALLS[int(info["wall"]) - 1]
		var wall := _slab(level["foundation"], cols, rows)
		wall.position = Vector2(float(info["x"]) - cols * PANO_BRICK.x * 0.5, LAND_Y - (rows + 1) * PANO_BRICK.y)
		add_child(wall)
		_walls.append(wall)
		if not built:
			for b in _bricks_of(wall):
				(b as Sprite2D).modulate.a = 0.0


func _king_name(i: int) -> String:
	var level: Dictionary = LevelData.WALLS[int(PANO_WALLS[i]["wall"]) - 1]
	return String(level["king"]).trim_prefix("King ")


func _raise_wall(i: int) -> void:
	var wall: Node2D = _walls[i]
	_build_up(wall, 0.75)
	var info: Dictionary = PANO_WALLS[i]
	_burst(Vector2(float(info["x"]), LAND_Y), FxData.DUST)
	var town: Node2D = _towns[i]
	if town.modulate.a < 1.0:
		var t := town.create_tween()
		t.tween_interval(0.5)
		t.tween_property(town, "modulate:a", 1.0, 0.5)


## Bricks appear row by row from the bottom, each dropping into place.
func _build_up(wall: Node2D, duration: float) -> void:
	var bricks := _bricks_of(wall)
	var low := -INF
	var high := INF
	for b in bricks:
		low = maxf(low, (b as Node2D).global_position.y)
		high = minf(high, (b as Node2D).global_position.y)
	for b in bricks:
		var s := b as Sprite2D
		var home := s.position.y
		var order := (low - s.global_position.y) / maxf(low - high, 1.0)
		s.position.y = home - 12.0
		var t := s.create_tween()
		t.tween_interval(order * duration + randf() * 0.06)
		t.tween_property(s, "modulate:a", 1.0, 0.1)
		t.parallel().tween_property(s, "position:y", home, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	GameState.audio.play("repair")


## Every brick above the last layer falls; an enemy flag goes up on what is left.
func _fall(i: int) -> void:
	var wall: Node2D = _walls[i]
	var bricks := _bricks_of(wall)
	var low := -INF
	var high := INF
	for b in bricks:
		low = maxf(low, (b as Node2D).global_position.y)
		high = minf(high, (b as Node2D).global_position.y)
	for b in bricks:
		var s := b as Sprite2D
		if s.global_position.y >= low - 1.0:
			continue                                   # the last layer stays
		var order := 1.0 - (low - s.global_position.y) / maxf(low - high, 1.0)
		var t := s.create_tween()
		t.tween_interval(order * 0.5 + randf() * 0.15)
		t.tween_property(s, "position:y", s.position.y + randf_range(30.0, 80.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(s, "rotation", randf_range(-1.2, 1.2), 0.45)
		t.parallel().tween_property(s, "modulate:a", 0.0, 0.45)
	var info: Dictionary = PANO_WALLS[i]
	var x := float(info["x"])
	_burst(Vector2(x, LAND_Y - 20.0), FxData.WALL_RUBBLE_SMALL)
	_burst(Vector2(x, LAND_Y - 10.0), FxData.DUST)
	GameState.audio.play("wall_crack")
	var fl := Scenery.flag(Scenery.ENEMY_RED, 40.0, Color8(60, 18, 20))
	fl.position = Vector2(x + 6.0, LAND_Y - PANO_BRICK.y)
	fl.scale = Vector2(1, 0)
	add_child(fl)
	var t2 := fl.create_tween()
	t2.tween_interval(0.7)
	t2.tween_property(fl, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if i < _plaques.size():
		(_plaques[i] as Control).modulate = Color(0.75, 0.6, 0.6)


## A name plate under wall i.
func _plaque(i: int, pop: bool) -> void:
	while _plaques.size() <= i:
		_plaques.append(null)
	if _plaques[i] != null:
		return
	var p := UI.panel(10, 3, true)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -4)
	p.add_child(col)
	col.add_child(UI.centered(UI.label(_king_name(i), 20, UI.INK)))
	add_child(p)
	p.reset_size()
	var size := p.get_combined_minimum_size()
	var x := float(PANO_WALLS[i]["x"])
	p.position = Vector2(x - size.x * 0.5, LAND_Y + 16.0)
	_plaques[i] = p
	if pop:
		p.modulate.a = 0.0
		p.position.y += 10.0
		var t := p.create_tween().set_parallel(true)
		t.tween_property(p, "modulate:a", 1.0, 0.25)
		t.tween_property(p, "position:y", LAND_Y + 16.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A small line of text just above wall i.
func _note(i: int, words: String) -> void:
	var l := UI.centered(UI.world_label(words, 18))
	add_child(l)
	l.reset_size()
	var info: Dictionary = PANO_WALLS[i]
	var rows: int = info["rows"]
	var x := float(info["x"])
	l.size = Vector2(180, l.size.y)
	l.position = Vector2(x - 90.0, LAND_Y - (rows + 1) * PANO_BRICK.y - l.size.y - 4.0)
	l.modulate.a = 0.0
	l.create_tween().tween_property(l, "modulate:a", 1.0, 0.4)


## A golden glow behind wall i.
func _glow(i: int) -> void:
	var info: Dictionary = PANO_WALLS[i]
	var rows: int = info["rows"]
	var g := Sprite2D.new()
	g.texture = _radial(Color(1.0, 0.86, 0.4, 0.75))
	var height := (rows + 1) * PANO_BRICK.y + 60.0
	g.scale = Vector2(220.0, height * 1.3) / 128.0
	g.position = Vector2(float(info["x"]), LAND_Y - height * 0.5 + 20.0)
	g.modulate.a = 0.0
	add_child(g)
	move_child(g, (_walls[0] as Node).get_index())     # behind the walls
	var t := g.create_tween()
	t.tween_property(g, "modulate:a", 1.0, 0.5)
	t.tween_property(g, "modulate:a", 0.55, 0.9).set_trans(Tween.TRANS_SINE)
	t.tween_property(g, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	t.set_loops()
	if i == 4:
		_burst(Vector2(float(info["x"]), LAND_Y - height * 0.5), FxData.SPARKS)


func _last_wall_title() -> void:
	var info: Dictionary = PANO_WALLS[4]
	var rows: int = info["rows"]
	var l := UI.centered(UI.world_label("THE LAST WALL", 30))
	l.add_theme_color_override("font_color", UI.BANNER)
	add_child(l)
	l.size = Vector2(300, 44)
	var top := LAND_Y - (rows + 1) * PANO_BRICK.y
	l.position = Vector2(float(info["x"]) - 150.0, top - 74.0)
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(1.4, 1.4)
	l.modulate.a = 0.0
	var t := l.create_tween().set_parallel(true)
	t.tween_property(l, "modulate:a", 1.0, 0.25)
	t.tween_property(l, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	GameState.audio.play("wall_held")


## The houses behind wall i (Zoa's small town, then the kingdom growing inland). Behind Aldren's: the castle.
func _town(i: int) -> Node2D:
	var town := Node2D.new()
	add_child(town)
	var info: Dictionary = PANO_WALLS[i]
	var half := float(info["cols"]) * PANO_BRICK.x * 0.5
	if i == PANO_WALLS.size() - 1:
		var art: String = LevelData.WALLS[0]["foundation"]
		var keep := _slab(art, 3, 12)
		keep.position = Vector2(1172, LAND_Y - 13 * PANO_BRICK.y)
		town.add_child(keep)
		var fl := Scenery.flag(Scenery.KINGDOM_BLUE, 44.0, Scenery.GOLD)
		fl.position = Vector2(1188, LAND_Y - 13 * PANO_BRICK.y)
		town.add_child(fl)
		town.add_child(_house(Vector2(1146, LAND_Y), Vector2(22, 18), Color8(176, 70, 52)))
		return town
	var left := float(info["x"]) + half + 6.0
	var right := float(PANO_WALLS[i + 1]["x"]) - float(PANO_WALLS[i + 1]["cols"]) * PANO_BRICK.x * 0.5 - 6.0
	var roofs := [Color8(176, 70, 52), Color8(150, 92, 60), Color8(190, 96, 64)]
	var x := left + 4.0
	var k := 0
	while x + 22.0 <= right:
		var w := 22.0 + (k % 2) * 6.0
		town.add_child(_house(Vector2(x + w * 0.5, LAND_Y), Vector2(w, 16.0 + (k % 3) * 4.0), roofs[k % roofs.size()]))
		x += w + 5.0
		k += 1
	return town


## A little house standing on `ground` (its bottom middle).
func _house(ground: Vector2, size: Vector2, roof: Color) -> Node2D:
	var n := Node2D.new()
	n.position = ground
	var w := size.x * 0.5
	n.add_child(_poly([Vector2(-w, 0), Vector2(-w, -size.y), Vector2(w, -size.y), Vector2(w, 0)], Color8(238, 226, 200)))
	n.add_child(_poly([Vector2(-w - 3, -size.y), Vector2(0, -size.y - 12), Vector2(w + 3, -size.y)], roof))
	n.add_child(_poly([Vector2(-3, 0), Vector2(-3, -8), Vector2(3, -8), Vector2(3, 0)], Color8(110, 74, 48)))
	n.add_child(_poly([Vector2(w - 8, -size.y + 4), Vector2(w - 3, -size.y + 4), Vector2(w - 3, -size.y + 9), Vector2(w - 8, -size.y + 9)], Color8(250, 214, 110)))
	return n


# ================================================================ war (scene 3)

func _war_shot() -> void:
	if _ships.is_empty() or _defenders.is_empty():
		return
	var ship: Node2D = _ships[randi() % _ships.size()]
	var target: Node2D = _defenders[randi() % _defenders.size()]
	var from := ship.position + Vector2(40, -14)
	var hit := target.position + Vector2(0, -34)
	_burst(from, FxData.SMALL_MUZZLE_FLASH, Vector2.RIGHT)
	GameState.audio.play("small_cannon")
	var ball := ArtData.make_sprite("cannonball", Vector2(10, 10))
	add_child(ball)
	_arc(ball, from, hit, 70.0, 0.6, func() -> void:
		_burst(hit, FxData.SPARKS, Vector2.LEFT)
		GameState.audio.play("bounce")
		ArtData.apply(ball, "stone_returned", Vector2(12, 12))
		_arc(ball, hit, ship.position + Vector2(0, -20), 50.0, 0.45, func() -> void:
			_burst(ball.position, FxData.EXPLOSION_SMALL)
			ship.modulate = Color(2, 2, 2)
			ship.create_tween().tween_property(ship, "modulate", Color.WHITE, 0.25)
			ball.queue_free()))


func _war_won() -> void:
	_volley.stop()
	for i in range(_ships.size()):
		var ship: Node2D = _ships[i]
		var t := ship.create_tween()
		t.tween_interval(0.35 * i)
		t.tween_callback(func() -> void:
			_burst(ship.position + Vector2(0, -10), FxData.EXPLOSION_SMALL)
			_burst(ship.position + Vector2(0, 10), FxData.SPLASH)
			GameState.audio.play("explosion"))
		t.tween_property(ship, "rotation", 0.35, 1.4)
		t.parallel().tween_property(ship, "position:y", ship.position.y + 70.0, 1.4).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(ship, "modulate:a", 0.0, 1.4)


func _war_price() -> void:
	if _sky:
		var day := _sky.vertex_colors
		_sky.create_tween().tween_method(func(v: float) -> void:
			_sky.vertex_colors = PackedColorArray([day[0].lerp(SUNSET_TOP, v), day[1].lerp(SUNSET_TOP, v), day[2].lerp(SUNSET_LOW, v), day[3].lerp(SUNSET_LOW, v)]), 0.0, 1.0, 2.5)
	var warm := create_tween()
	warm.tween_property(self, "modulate", Color(1.0, 0.92, 0.84), 2.5)
	for i in range(_defenders.size()):
		if i == 1:
			continue                                   # one of them is left
		var s: Node2D = _defenders[i]
		s.create_tween().tween_property(s, "modulate:a", 0.0, 1.5)
	if _war_flag:
		_war_flag.create_tween().tween_property(_war_flag, "position:y", _war_flag.position.y + 18.0, 2.0)


func _war_graves() -> void:
	for i in range(6):
		var g := _grave()
		g.scale = Vector2(1.5, 1.5)
		g.position = Vector2(950.0 + i * 50.0 + (i % 2) * 6.0, 364.0 + (i % 2) * 8.0)
		g.modulate.a = 0.0
		add_child(g)
		var t := g.create_tween()
		t.tween_interval(0.25 * i)
		t.tween_property(g, "modulate:a", 1.0, 0.6)


## A sword planted in the ground with a round shield leaning on it.
func _grave() -> Node2D:
	var n := Node2D.new()
	var blade := Line2D.new()
	blade.points = PackedVector2Array([Vector2(0, 0), Vector2(0, -34)])
	blade.width = 3.0
	blade.default_color = Color8(214, 220, 230)
	n.add_child(blade)
	var guard := Line2D.new()
	guard.points = PackedVector2Array([Vector2(-8, -26), Vector2(8, -26)])
	guard.width = 3.0
	guard.default_color = Color8(150, 110, 60)
	n.add_child(guard)
	var shield := ArtData.make_sprite("shield", Vector2(26, 21))
	shield.position = Vector2(6, -8)
	shield.rotation = 0.25
	n.add_child(shield)
	n.add_child(_poly([Vector2(-12, 0), Vector2(14, 0), Vector2(10, 4), Vector2(-9, 4)], Color8(110, 86, 60)))
	return n


# ================================================================ sails (scene 4)

## A ship appears far away on the horizon and slowly comes closer.
func _far_ship(at: Vector2, delay: float) -> void:
	var holder := Node2D.new()
	holder.position = at
	holder.modulate = Color(0.78, 0.84, 0.94, 0.0)
	add_child(holder)
	move_child(holder, _first_sea_child() + 1)
	var s := ArtData.make_sprite("ship")
	var k := randf_range(0.1, 0.16)
	s.scale *= k
	s.position = Vector2(0, -ArtData.size_of("ship").y * 0.5 * k + 3.0)
	holder.add_child(s)
	var t := holder.create_tween()
	t.tween_interval(delay)
	t.tween_property(holder, "modulate:a", 1.0, 0.8)
	var come := holder.create_tween().set_parallel(true)
	come.tween_property(holder, "scale", Vector2.ONE * 1.8, 18.0)
	come.tween_property(holder, "position:y", at.y + 34.0, 18.0)


func _first_sea_child() -> int:
	return _sea_index if _sea_index >= 0 else get_child_count() - 1


# ================================================================ king (scene 6)

func _window(r: Rect2) -> void:
	var pts := PackedVector2Array()
	var cx := r.position.x + r.size.x * 0.5
	var rad := r.size.x * 0.5
	pts.append(Vector2(r.position.x, r.end.y))
	for i in range(13):
		var a := PI + PI * i / 12.0
		pts.append(Vector2(cx + cos(a) * rad, r.position.y + rad + sin(a) * rad))
	pts.append(Vector2(r.end.x, r.end.y))
	var pane := Polygon2D.new()
	pane.polygon = pts
	var colors := PackedColorArray()
	for p in pts:
		colors.append(Scenery.SKY_TOP.lerp(Color8(214, 236, 250), (p.y - r.position.y) / r.size.y))
	pane.vertex_colors = colors
	add_child(pane)
	var closed := Array(pts)
	closed.append(pts[0])
	add_child(_outline(closed, Color8(150, 112, 64), 8.0))
	add_child(_outline([Vector2(cx, r.position.y + 4), Vector2(cx, r.end.y)], Color8(150, 112, 64), 4.0))
	add_child(_outline([Vector2(r.position.x, r.position.y + r.size.y * 0.55), Vector2(r.end.x, r.position.y + r.size.y * 0.55)], Color8(150, 112, 64), 4.0))


func _awaken_shield() -> void:
	_shield.create_tween().tween_property(_shield, "modulate", Color(1.15, 1.12, 1.0), 0.8)
	var t := _aura.create_tween()
	t.tween_property(_aura, "modulate:a", 1.0, 0.6)
	t.tween_property(_aura, "modulate:a", 0.6, 0.8).set_trans(Tween.TRANS_SINE)
	t.tween_property(_aura, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	t.set_loops()
	_sparkles = CPUParticles2D.new()
	_sparkles.position = Vector2(900, 330)
	_sparkles.amount = 26
	_sparkles.lifetime = 1.6
	_sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_sparkles.emission_rect_extents = Vector2(90, 60)
	_sparkles.direction = Vector2(0, -1)
	_sparkles.spread = 20.0
	_sparkles.gravity = Vector2.ZERO
	_sparkles.initial_velocity_min = 14.0
	_sparkles.initial_velocity_max = 34.0
	_sparkles.scale_amount_min = 2.0
	_sparkles.scale_amount_max = 4.0
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 0.86, 0.4, 0.0), Color(1, 0.9, 0.5, 1.0), Color(1, 0.86, 0.4, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	_sparkles.color_ramp = g
	add_child(_sparkles)
	_burst(Vector2(900, 300), FxData.SPARKS)
	GameState.audio.play("bounce")


func _speech() -> void:
	var bubble := UI.panel(20, 10, true)
	var l := UI.label("\"Call the hero.\"", 30)
	bubble.add_child(l)
	add_child(bubble)
	bubble.reset_size()
	bubble.position = Vector2(566, 126)
	var tail := _poly([Vector2(590, 126 + bubble.size.y - 2), Vector2(626, 126 + bubble.size.y - 2), Vector2(522, 262)], Color(UI.PAPER, 1.0))
	add_child(tail)
	move_child(tail, bubble.get_index())
	for node in [bubble, tail]:
		var c := node as CanvasItem
		c.modulate.a = 0.0
		c.create_tween().tween_property(c, "modulate:a", 1.0, 0.25)
	bubble.pivot_offset = Vector2(0, bubble.size.y)
	bubble.scale = Vector2(0.7, 0.7)
	bubble.create_tween().tween_property(bubble, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ================================================================ hero (scene 7)

func _hero_shot() -> void:
	if _cannons.is_empty():
		return
	var spec: Dictionary = _cannons[_next_cannon % _cannons.size()]
	_next_cannon += 1
	var cannon: Sprite2D = spec["sprite"]
	var muzzle: Vector2 = spec["muzzle"]
	var anim := cannon.create_tween()
	for f in [2, 3, 4, 5, 6, 7, 0]:
		var frame: int = f
		anim.tween_callback(func() -> void: cannon.frame = frame)
		anim.tween_interval(1.0 / 14.0)
	_burst(muzzle, FxData.SMALL_MUZZLE_FLASH, Vector2.DOWN)
	_burst(muzzle, FxData.CANNON_SMOKE)
	GameState.audio.play("small_cannon")
	var center := _aura.position
	var side := randf_range(-0.5, 0.5)
	var rx := 70.0 * 1.4
	var hit := center + Vector2(side * rx, -GameData.AURA_HEIGHT * 1.4 * sqrt(1.0 - side * side) - 8.0)
	var ball := ArtData.make_sprite("cannonball")
	ball.position = muzzle
	add_child(ball)
	var t := ball.create_tween()
	t.tween_property(ball, "position", hit, 1.0)
	t.tween_callback(func() -> void:
		_burst(hit, FxData.SPARKS, Vector2.UP)
		GameState.audio.play("bounce")
		_flash_aura()
		ArtData.apply(ball, "stone_returned")
		var trail := FxScript.make_trail(FxData.TRAIL)
		ball.add_child(trail))
	t.tween_property(ball, "position", cannon.position, 0.55)
	t.tween_callback(func() -> void:
		_burst(cannon.position, FxData.GOLD_CHIPS)
		_burst(cannon.position, FxData.EXPLOSION_SMALL)
		GameState.audio.play("enemy_hit")
		cannon.self_modulate = Color(3, 3, 3)
		cannon.create_tween().tween_property(cannon, "self_modulate", Color.WHITE, 0.2)
		_coin_pop(cannon.position + Vector2(-14, 10))
		ball.queue_free())


func _flash_aura() -> void:
	if not _hero_aura:
		return
	_hero_aura.modulate = Color(1.8, 1.8, 1.8)
	_hero_glow.modulate = Color(2.2, 2.2, 2.2)
	var t := _hero_aura.create_tween().set_parallel(true)
	t.tween_property(_hero_aura, "modulate", Color.WHITE, 0.3)
	t.tween_property(_hero_glow, "modulate", Color.WHITE, 0.3)


func _coin_pop(at: Vector2) -> void:
	var coin := ArtData.make_sprite("coin_spin")
	coin.position = at
	add_child(coin)
	var frames := coin.hframes
	var label := UI.world_label("+5", 22)
	label.add_theme_color_override("font_color", FxData.COIN_COLOR)
	label.position = at + Vector2(20, -16)
	add_child(label)
	var t := coin.create_tween().set_parallel(true)
	t.tween_method(func(v: float) -> void: coin.frame = int(v) % frames, 0.0, float(frames * 2) - 0.01, 0.8)
	t.tween_property(coin, "position:y", at.y - 40.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(label, "position:y", at.y - 56.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(coin, "modulate:a", 0.0, 0.4).set_delay(0.4)
	t.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.4)
	t.chain().tween_callback(func() -> void:
		coin.queue_free()
		label.queue_free())


## A golden ring that grows out of the shield and fades.
func _ring_wave(at: Vector2) -> Line2D:
	var ring := Line2D.new()
	var pts := PackedVector2Array()
	for i in range(33):
		var a := TAU * i / 32.0
		pts.append(Vector2(cos(a), sin(a) * 0.7) * 40.0)
	ring.points = pts
	ring.width = 5.0
	ring.default_color = GameData.AURA_COLOR
	ring.position = at
	var t := ring.create_tween().set_parallel(true)
	t.tween_property(ring, "scale", Vector2.ONE * 5.0, 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(ring, "modulate:a", 0.0, 0.9)
	t.chain().tween_callback(ring.queue_free)
	_flash_aura()
	GameState.audio.play("wall_held")
	return ring


# ================================================================ building blocks

func _sky_and_clouds(bottom: float, top_color: Color = Scenery.SKY_TOP, low_color: Color = Scenery.SKY_LOW) -> void:
	_sky = Scenery.gradient_rect(Rect2(0, 0, W, bottom), top_color, low_color)
	add_child(_sky)
	_clouds = Node2D.new()
	add_child(_clouds)
	for i in range(5):
		var c := Scenery.cloud(randf_range(110.0, 170.0), randf_range(6.0, 14.0))
		c.position = Vector2(i * 270.0 + randf_range(0, 120), randf_range(40.0, bottom * 0.4))
		_clouds.add_child(c)


func _sea(r: Rect2, top: Color = Color8(110, 180, 226), deep: Color = Color8(40, 104, 172)) -> void:
	add_child(Scenery.gradient_rect(r, top, deep))
	var waves := Node2D.new()
	add_child(waves)
	_sea_index = waves.get_index()
	var count := int(r.size.x * minf(r.size.y, 260.0) / 5000.0)
	for i in range(count):
		var w := Line2D.new()
		var depth := randf() * randf()
		var length := lerpf(8.0, 22.0, depth)
		w.points = PackedVector2Array([Vector2(-length * 0.5, 0), Vector2(length * 0.5, 0)])
		w.width = lerpf(1.0, 2.5, depth)
		w.default_color = Color(1, 1, 1, 0.55)
		w.position = Vector2(r.position.x + randf() * r.size.x, r.position.y + 6.0 + depth * minf(r.size.y - 10.0, 250.0))
		waves.add_child(w)
		var t := w.create_tween().set_loops()
		var speed := randf_range(1.2, 2.2)
		t.tween_property(w, "position:x", w.position.x + 8.0, speed).set_trans(Tween.TRANS_SINE)
		t.tween_property(w, "position:x", w.position.x, speed).set_trans(Tween.TRANS_SINE)


## The land from the shore to the right edge: a sandy beach, then grass on top of the earth.
func _land(shore: float, top: float) -> void:
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(shore - 50, H), Vector2(shore - 50, top + 26), Vector2(shore + 20, top + 8), Vector2(shore + 80, top), Vector2(W, top), Vector2(W, H)])
	body.vertex_colors = PackedColorArray([Color8(130, 98, 66), Color8(214, 190, 136), Color8(222, 198, 142), Color8(150, 114, 76), Color8(150, 114, 76), Color8(120, 90, 60)])
	add_child(body)
	add_child(_outline([Vector2(shore + 60, top + 2), Vector2(W, top + 2)], Color8(112, 176, 74), 8.0))
	add_child(_poly([Vector2(shore - 50, top + 26), Vector2(shore + 20, top + 8), Vector2(shore + 80, top), Vector2(shore + 80, top + 10), Vector2(shore + 20, top + 20), Vector2(shore - 50, top + 38)], Color8(232, 212, 158)))


## A wall seen from the side: `cols` bricks thick, `rows` high, laid like real masonry, battlements on top.
## Its top-left corner is at (0, 0); it is (rows + 1) bricks tall.
func _slab(art: String, cols: int, rows: int) -> Node2D:
	var node := Node2D.new()
	var merlons := "#.#" if cols == 3 else ("#..#" if cols == 4 else "#.#.#")
	var top := Scenery.wall([merlons], art, PANO_BRICK)
	node.add_child(top)
	var lines := []
	for r in range(rows):
		var shifted := (rows - 1 - r) % 2 == 1
		var line := ""
		for c in range(cols + (1 if shifted else 0)):
			line += "#"
		lines.append(line)
	var body := Scenery.wall(lines, art, PANO_BRICK, "running")
	body.position = Vector2(0, PANO_BRICK.y)
	node.add_child(body)
	return node


func _ship(k: float, waterline: Vector2) -> Node2D:
	var holder := Node2D.new()
	holder.position = waterline
	var s := ArtData.make_sprite("ship")
	s.scale *= k
	s.position = Vector2(0, -ArtData.size_of("ship").y * 0.5 * k + 10.0 * k)
	holder.add_child(s)
	add_child(holder)
	var t := holder.create_tween().set_loops()
	var speed := randf_range(1.1, 1.5)
	t.tween_property(s, "rotation", 0.035, speed).set_trans(Tween.TRANS_SINE)
	t.tween_property(s, "rotation", -0.035, speed).set_trans(Tween.TRANS_SINE)
	return holder


## One of our soldiers (the hero's look, smaller), standing with his feet at (0, 0).
func _soldier(k: float) -> Node2D:
	var n := Node2D.new()
	var body_y := -52.0 * k
	var shield := ArtData.make_sprite("shield")
	shield.scale *= k
	shield.position = Vector2(0, body_y + GameData.SHIELD_CENTER_Y * k)
	n.add_child(shield)
	var body := ArtData.make_sprite("hero")
	body.scale *= k
	body.position = Vector2(0, body_y)
	n.add_child(body)
	return n


## The golden aura arcs over a shield (like in the game). Child 0 = glow, child 1 = the line.
func _arcs(center: Vector2, rx: float, height: float, alpha: float) -> Node2D:
	var n := Node2D.new()
	n.position = center
	for spec in [[GameData.AURA_GLOW_WIDTH * 1.4, GameData.AURA_GLOW_ALPHA * 1.4], [GameData.AURA_WIDTH * 1.4, alpha]]:
		var line := Line2D.new()
		line.width = spec[0]
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		var c := GameData.AURA_COLOR
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
		g.colors = PackedColorArray([Color(c, 0.0), Color(c, spec[1]), Color(c, spec[1]), Color(c, 0.0)])
		line.gradient = g
		var pts := PackedVector2Array()
		for i in range(GameData.AURA_POINTS + 1):
			var a := PI + PI * float(i) / GameData.AURA_POINTS
			pts.append(Vector2(cos(a) * rx, sin(a) * height))
		line.points = pts
		n.add_child(line)
	return n


## Moves `node` from a to b along a curve (`lift` px high), then calls `done`.
func _arc(node: Node2D, a: Vector2, b: Vector2, lift: float, time: float, done: Callable) -> void:
	node.position = a
	var t := node.create_tween()
	t.tween_method(func(v: float) -> void: node.position = a.lerp(b, v) + Vector2(0, -lift * 4.0 * v * (1.0 - v)), 0.0, 1.0, time)
	t.tween_callback(done)


func _burst(pos: Vector2, preset: Dictionary, direction: Vector2 = Vector2.ZERO) -> void:
	var p := FxScript.make_burst(pos, preset, direction)
	if p:
		p.z_index = 5
		add_child(p)
		p.emitting = true


func _bricks_of(node: Node) -> Array:
	var out := []
	for child in node.get_children():
		if child is Sprite2D:
			out.append(child)
		elif child is Node2D:
			out.append_array(_bricks_of(child))
	return out


func _poly(points: Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(points)
	p.color = color
	return p


func _outline(points: Array, color: Color, width: float) -> Line2D:
	var l := Line2D.new()
	l.points = PackedVector2Array(points)
	l.width = width
	l.default_color = color
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	return l


func _circle(center: Vector2, r: float, color: Color) -> Polygon2D:
	var pts := []
	for i in range(16):
		pts.append(center + Vector2(cos(TAU * i / 16.0), sin(TAU * i / 16.0)) * r)
	return _poly(pts, color)


## A soft round glow picture (128 x 128).
func _radial(color: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([color, Color(color, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 128
	t.height = 128
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t
