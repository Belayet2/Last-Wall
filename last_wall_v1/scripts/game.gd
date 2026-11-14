extends Node2D
## The play field for the current wall: builds the world, wall, hero, enemies (or the boss) and HUD,
## and runs the "Bounce Back" loop:
##   build      -> lay your bricks on the wall (the enemies wait), then Fight!
##   wave cleared -> the bricks still standing are mended, retake bonus, then Shop / Next Wall.
##                   The next wall has only its last layer left: you build on it. Last wall: Victory.
##   a last-layer brick breaks -> the wall falls: fall back one wall (or Game Over on Wall 1)

const GameData = preload("res://scripts/data/game_data.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const BrickData = preload("res://scripts/data/brick_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const FxData = preload("res://scripts/data/fx_data.gd")
const WallScript = preload("res://scripts/wall.gd")
const HeroScript = preload("res://scripts/hero.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const BossScript = preload("res://scripts/boss.gd")
const EnemyData = preload("res://scripts/data/enemy_data.gd")
const HudScript = preload("res://scripts/hud.gd")
const FxScript = preload("res://scripts/fx.gd")

var _level: Dictionary
var _wall: WallScript
var _hero: Node2D
var _hud: HudScript
var _fx: FxScript
var _boss: BossScript
var _enemies: Array[Node] = []
var _stones: Node2D
var _markers: Node2D
var _alive := 0
var _fighting := false
var _ended := false
var _arrived_fresh := false
var _continue_text := "Continue"


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	var number := GameState.current_wall
	_level = LevelData.WALLS[number - 1]
	_arrived_fresh = GameState.arriving_fresh()

	build_world(self, number)

	_fx = FxScript.new()
	add_child(_fx)

	_markers = Node2D.new()
	_markers.name = "Markers"
	add_child(_markers)

	_wall = WallScript.new()
	_wall.setup(GameState.current_layout(), _level["foundation"])
	add_child(_wall)
	_wall.foundation_changed.connect(_on_foundation_changed)
	_wall.wall_fallen.connect(_on_wall_fallen)

	_hero = HeroScript.new()
	add_child(_hero)

	_stones = Node2D.new()
	_stones.name = "Stones"
	_stones.z_index = 2
	add_child(_stones)

	_hud = HudScript.new()
	add_child(_hud)
	_hud.action_chosen.connect(_on_action)
	_hud.setup_wall(number, _level["title"])
	var weakest := _wall.weakest_foundation()
	_hud.set_wall_hp(weakest.x, weakest.y)
	_hud.set_coins(GameState.coins)
	GameState.coins_changed.connect(_hud.set_coins)

	if not _level.get("boss", false):
		_spawn_enemies(_level)
		_hud.set_enemies(_enemy_icons(_level))
	_start_building()


## Background used by the game and the main menu (wall_number picks the backdrop and ground).
static func build_world(parent: Node, wall_number: int = 1) -> void:
	var level: Dictionary = LevelData.WALLS[wall_number - 1]
	var cx := GameData.SCREEN_WIDTH * 0.5
	_add_bg(parent, level["backdrop"], Vector2(cx, GameData.RUINS_TOP + GameData.RUINS_HEIGHT * 0.5), false, -10)
	_add_bg(parent, level["ground"], Vector2(cx, GameData.GROUND_TOP + GameData.GROUND_HEIGHT * 0.5), false, -10)
	_add_bg(parent, "path", Vector2(cx, GameData.PATH_TOP + GameData.PATH_HEIGHT * 0.5), false, -10)
	var rocks_y := GameData.GROUND_TOP + (GameData.GROUND_HEIGHT + GameData.PATH_HEIGHT) * 0.5
	_add_bg(parent, "edge_rocks", Vector2(GameData.EDGE_ROCKS_X, rocks_y), false, -9)
	_add_bg(parent, "edge_rocks", Vector2(GameData.SCREEN_WIDTH - GameData.EDGE_ROCKS_X, rocks_y), true, -9)


static func _add_bg(parent: Node, key: String, center: Vector2, flip: bool, z: int) -> void:
	var s := ArtData.make_sprite(key)
	s.position = center
	s.flip_h = flip
	s.z_index = z
	parent.add_child(s)


# ---------------------------------------------------------------- build, then fight

func _start_building() -> void:
	_set_fighters_active(false)
	_hud.open_build(_wall, _danger_map(), _build_intro())


func _build_intro() -> String:
	var number := GameState.current_wall
	var text := ""
	if number == 1 and _arrived_fresh and GameState.falls == 0 and GameState.enemies_defeated == 0:
		text = "The king gives you %d clay bricks. Lay them on top of the last layer (the bottom row). " % GameState.total_bricks()
	elif _arrived_fresh:
		text = "The enemy left only the last layer (the bottom row). Build on top of it with the bricks you bought. "
	else:
		text = "Your bricks are still here, mended. Add more if you have them. "
	return text + "If ANY brick of the last layer breaks, the wall falls!"


func _start_fight() -> void:
	if _fighting or _ended:
		return
	_fighting = true
	_set_fighters_active(true)
	if _level.get("boss", false):
		_spawn_boss()
	_hud.show_intro(GameState.current_wall, _level["title"], _level["tip"])
	GameState.audio.play("horn")


## Enemies and the hero wait (frozen) while you build.
func _set_fighters_active(on: bool) -> void:
	var mode := Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	_hero.process_mode = mode
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.process_mode = mode


## How hard the enemies hit each column, 0..1 (shown as red strips on the build screen).
func _danger_map() -> Array:
	var values := []
	values.resize(BrickData.COLUMNS)
	values.fill(0.0)
	if _level.get("boss", false):
		values.fill(0.5)                 # the flagship fires all along the wall
		return values
	var margin := EnemyData.TARGET_EDGE_MARGIN
	for enemy in _enemies:
		var info: Dictionary = enemy.data
		var x: float = (enemy as Node2D).position.x
		var lo := maxf(x - float(info["aim_spread"]), GameData.FIELD_LEFT + margin)
		var hi := minf(x + float(info["aim_spread"]), GameData.FIELD_RIGHT - margin)
		var power := float(info["wall_damage"]) / float(info["throw_interval"]) / (hi - lo)
		for col in range(BrickData.COLUMNS):
			var cx := BrickData.COLUMN_LEFT + BrickData.BRICK_W * (col + 0.5)
			if cx >= lo - BrickData.BRICK_W * 0.5 and cx <= hi + BrickData.BRICK_W * 0.5:
				values[col] += power
	var most: float = values.max()
	if most > 0.0:
		for col in range(values.size()):
			values[col] = values[col] / most
	return values


# ---------------------------------------------------------------- enemies

func _spawn_enemies(level: Dictionary) -> void:
	var types: Array = level["enemies"]
	var count := types.size()
	var field_width := GameData.FIELD_RIGHT - GameData.FIELD_LEFT
	for i in range(count):
		var enemy := EnemyScript.new()
		enemy.setup(types[i], i, level["max_stones"], _stones, _markers)
		enemy.position = Vector2(GameData.FIELD_LEFT + field_width * (i + 1) / (count + 1), GameData.ENEMY_Y)
		enemy.died.connect(_on_enemy_died)
		add_child(enemy)
		_enemies.append(enemy)
		_alive += 1


func _spawn_boss() -> void:
	_boss = BossScript.new()
	_boss.setup(_stones, _markers)
	_boss.died.connect(_on_enemy_died)
	_boss.hp_changed.connect(_hud.set_boss_hp)
	_boss.phase_changed.connect(_on_boss_phase)
	add_child(_boss)
	_alive = 1
	_hud.show_boss(EnemyData.BOSS["name"], _boss.max_hp)
	var arrive: float = EnemyData.BOSS["enter_time"]
	get_tree().create_timer(arrive).timeout.connect(_on_boss_arrived)


func _on_boss_arrived() -> void:
	GameState.audio.play("boss_horn")
	_fx.shake(FxData.SHAKE_BOSS_ARRIVE)
	_hud.show_banner(EnemyData.BOSS["name"], "Bounce its cannonballs back to sink it!")


func _on_boss_phase(phase: int) -> void:
	GameState.audio.play("boss_horn")
	_fx.shake(FxData.SHAKE_BOSS_ARRIVE)
	if phase == 1:
		_hud.show_banner("The flagship is angry!", "Three cannonballs at once now.")
	else:
		_hud.show_banner("Last stand!", "Four cannonballs. Hold on!")


func _enemy_icons(level: Dictionary) -> Array:
	var keys := []
	for type_key in level["enemies"]:
		keys.append(EnemyData.TYPES[type_key]["icon"])
	return keys


func _on_enemy_died(enemy: Node) -> void:
	var coins: int = enemy.data["coins"]
	GameState.add_coins(coins)
	GameState.enemies_defeated += 1
	GameState.audio.play("coin")
	_fx.float_text((enemy as Node2D).global_position + Vector2(0, FxData.COIN_TEXT_OFFSET_Y), "+%d" % coins, FxData.COIN_COLOR)
	_fx.hit_stop()
	_alive -= 1
	if enemy != _boss:
		_hud.mark_enemy_down(enemy.index)
	if _alive <= 0 and not _ended:
		_on_wave_cleared()


# ---------------------------------------------------------------- end of the wave

func _on_wave_cleared() -> void:
	for stone in get_tree().get_nodes_in_group("stones"):
		stone.shatter()
	var number := GameState.current_wall
	_wall.heal_full()
	var bonus := GameState.wave_cleared(_wall.get_layout())
	GameState.audio.play("wall_held")
	_fx.float_text(Vector2(GameData.FIELD_CENTER_X, GameData.WALL_TOP - 10), "Retake bonus +%d" % bonus, FxData.COIN_COLOR)
	if GameState.is_last_wall():
		_finish("win", "Victory!", "The flagship sinks. Every wall is ours again.")
		return
	GameState.advance()
	var next := GameState.current_wall
	_continue_text = "Go to Wall %d" % next
	var note := "Only its last layer is left: buy bricks to build on it." if GameState.arriving_fresh() else ""
	_end("Wall %d Held!" % number,
		"Your bricks are mended. Retake bonus: +%d coins.\nNext: Wall %d - %s\n%s" % [bonus, next, GameState.wall_title(next), note],
		[["Shop", "shop", false], ["Next Wall", "next", true]])


func _on_wall_fallen() -> void:
	if _ended:
		return
	var lost := GameState.current_wall
	if lost == 1:
		_finish("lose", "The Last Wall Fell", "A hole in the last layer. There is no wall left to fall back to.")
		return
	GameState.audio.play("wall_fell")
	GameState.fall_back()
	var back := GameState.current_wall
	_continue_text = "Defend Wall %d" % back
	_end("Wall %d Fell!" % lost,
		"A hole in the last layer! Bounce back to Wall %d and hold it." % back,
		[["Shop", "shop", false], ["Fight", "next", true]])


func _on_foundation_changed(hp: int, max_hp: int) -> void:
	_hud.set_wall_hp(hp, max_hp)


func _end(title: String, subtitle: String, buttons: Array) -> void:
	_ended = true
	_hud.show_end(title, subtitle, buttons)
	await get_tree().create_timer(GameData.END_PAUSE_DELAY).timeout
	get_tree().paused = true


## Final result: show the title for a moment, then go to the win / lose screen.
func _finish(result: String, title: String, subtitle: String) -> void:
	GameState.last_result = result
	_end(title, subtitle, [])
	var delay := GameData.FINISH_DELAY_BOSS if _boss else GameData.FINISH_DELAY
	await get_tree().create_timer(delay, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/end_screen.tscn")


func _on_action(action: String) -> void:
	match action:
		"menu":
			GameState.reset()
			Engine.time_scale = 1.0
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		"restart":
			GameState.reset()
			_reload()
		"next":
			_reload()                         # the next wave starts with the build screen
		"shop":
			_hud.open_shop(_continue_text)
		"build":
			_hud.open_build(_wall, _danger_map(), _build_intro())
		"fight":
			_start_fight()


func _reload() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()
