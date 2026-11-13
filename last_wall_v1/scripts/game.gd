extends Node2D
## The play field for the current wall: builds the world, wall, hero, enemies and HUD,
## and runs the "Bounce Back" loop when the wave ends:
##   wave cleared -> wall heals to 100%, retake bonus, then Shop / Next Wall (or Victory on the last wall)
##   wall falls   -> fall back one wall, then Shop / Fight (or Game Over on Wall 1)

const GameData = preload("res://scripts/data/game_data.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const FxData = preload("res://scripts/data/fx_data.gd")
const WallScript = preload("res://scripts/wall.gd")
const HeroScript = preload("res://scripts/hero.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const EnemyData = preload("res://scripts/data/enemy_data.gd")
const HudScript = preload("res://scripts/hud.gd")
const FxScript = preload("res://scripts/fx.gd")

var _wall: WallScript
var _hud: HudScript
var _fx: FxScript
var _stones: Node2D
var _markers: Node2D
var _alive := 0
var _ended := false
var _continue_text := "Continue"


func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	var number := GameState.current_wall
	var level: Dictionary = LevelData.WALLS[number - 1]
	var max_hp: int = level["max_hp"]
	var start_hp := GameState.begin_wave()

	_build_world()

	_fx = FxScript.new()
	add_child(_fx)

	_markers = Node2D.new()
	_markers.name = "Markers"
	add_child(_markers)

	_wall = WallScript.new()
	_wall.setup(max_hp, start_hp)
	add_child(_wall)
	_wall.hp_changed.connect(_on_wall_hp_changed)
	_wall.wall_fallen.connect(_on_wall_fallen)

	add_child(HeroScript.new())

	_stones = Node2D.new()
	_stones.name = "Stones"
	_stones.z_index = 2
	add_child(_stones)

	_spawn_enemies(level)

	_hud = HudScript.new()
	add_child(_hud)
	_hud.action_chosen.connect(_on_action)
	_hud.setup_wall(number, level["title"])
	_hud.set_wall_hp(start_hp, max_hp)
	_hud.set_enemies(_enemy_icons(level))
	_hud.set_coins(GameState.coins)
	GameState.coins_changed.connect(_hud.set_coins)
	_hud.show_intro(number, level["title"], level["tip"])


func _build_world() -> void:
	var cx := GameData.SCREEN_WIDTH * 0.5
	_add_bg("ruins", Vector2(cx, GameData.RUINS_TOP + GameData.RUINS_HEIGHT * 0.5), false, -10)
	_add_bg("ground", Vector2(cx, GameData.GROUND_TOP + GameData.GROUND_HEIGHT * 0.5), false, -10)
	_add_bg("path", Vector2(cx, GameData.PATH_TOP + GameData.PATH_HEIGHT * 0.5), false, -10)
	var rocks_y := GameData.GROUND_TOP + (GameData.GROUND_HEIGHT + GameData.PATH_HEIGHT) * 0.5
	_add_bg("edge_rocks", Vector2(GameData.EDGE_ROCKS_X, rocks_y), false, -9)
	_add_bg("edge_rocks", Vector2(GameData.SCREEN_WIDTH - GameData.EDGE_ROCKS_X, rocks_y), true, -9)


func _add_bg(key: String, center: Vector2, flip: bool, z: int) -> void:
	var s := ArtData.make_sprite(key)
	s.position = center
	s.flip_h = flip
	s.z_index = z
	add_child(s)


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
		_alive += 1


func _enemy_icons(level: Dictionary) -> Array:
	var keys := []
	for type_key in level["enemies"]:
		keys.append(EnemyData.TYPES[type_key]["icon"])
	return keys


func _on_enemy_died(enemy: Node) -> void:
	var coins: int = enemy.data["coins"]
	GameState.add_coins(coins)
	_fx.float_text((enemy as Node2D).global_position + Vector2(0, FxData.COIN_TEXT_OFFSET_Y), "+%d" % coins, FxData.COIN_COLOR)
	_fx.hit_stop()
	_alive -= 1
	_hud.mark_enemy_down(enemy.index)
	if _alive <= 0 and not _ended:
		_on_wave_cleared()


func _on_wave_cleared() -> void:
	for stone in get_tree().get_nodes_in_group("stones"):
		stone.shatter()
	var number := GameState.current_wall
	var bonus := GameState.wave_cleared()
	_wall.heal_full()
	_fx.float_text(Vector2(GameData.FIELD_CENTER_X, GameData.WALL_TOP - 10), "Retake bonus +%d" % bonus, FxData.COIN_COLOR)
	if GameState.is_last_wall():
		_end("Victory!", "Every wall is ours again. The kingdom is saved.", [["Play again", "restart", true]])
		return
	GameState.advance()
	var next := GameState.current_wall
	_continue_text = "Go to Wall %d" % next
	_end("Wall %d Held!" % number,
		"Retake bonus: +%d coins.\nNext: Wall %d - %s" % [bonus, next, GameState.wall_title(next)],
		[["Shop", "shop", false], ["Next Wall", "next", true]])


func _on_wall_fallen() -> void:
	if _ended:
		return
	var lost := GameState.current_wall
	if lost == 1:
		_end("The Last Wall Fell", "The last wall has fallen.", [["Try again", "restart", true]])
		return
	GameState.fall_back()
	var back := GameState.current_wall
	_continue_text = "Defend Wall %d" % back
	_end("Wall %d Fell!" % lost,
		"Bounce back! Fall back to Wall %d and hold it." % back,
		[["Shop", "shop", false], ["Fight", "next", true]])


func _on_wall_hp_changed(hp: int, max_hp: int) -> void:
	_hud.set_wall_hp(hp, max_hp)


func _end(title: String, subtitle: String, buttons: Array) -> void:
	_ended = true
	_hud.show_end(title, subtitle, buttons)
	await get_tree().create_timer(GameData.END_PAUSE_DELAY).timeout
	get_tree().paused = true


func _on_action(action: String) -> void:
	match action:
		"restart":
			GameState.reset()
			_reload()
		"next":
			_reload()
		"shop":
			_hud.open_shop(_continue_text)


func _reload() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()
