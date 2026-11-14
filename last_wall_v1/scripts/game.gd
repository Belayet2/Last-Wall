extends Node2D
## The play field for the current wall: builds the world, wall, hero, enemies (or the boss) and HUD,
## and runs the "Bounce Back" loop when the wave ends:
##   wave cleared -> wall heals to 100%, retake bonus, then Shop / Next Wall
##                   (moving out to a fallen wall: pay to repair it first). Last wall: Victory.
##   wall falls   -> fall back one wall, then Shop / Fight (or Game Over on Wall 1)

const GameData = preload("res://scripts/data/game_data.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const FxData = preload("res://scripts/data/fx_data.gd")
const WallScript = preload("res://scripts/wall.gd")
const HeroScript = preload("res://scripts/hero.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const BossScript = preload("res://scripts/boss.gd")
const EnemyData = preload("res://scripts/data/enemy_data.gd")
const HudScript = preload("res://scripts/hud.gd")
const FxScript = preload("res://scripts/fx.gd")

var _wall: WallScript
var _hud: HudScript
var _fx: FxScript
var _boss: BossScript
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

	build_world(self, number)

	_fx = FxScript.new()
	add_child(_fx)

	_markers = Node2D.new()
	_markers.name = "Markers"
	add_child(_markers)

	_wall = WallScript.new()
	_wall.setup(max_hp, start_hp, level["art"])
	add_child(_wall)
	_wall.hp_changed.connect(_on_wall_hp_changed)
	_wall.wall_fallen.connect(_on_wall_fallen)

	add_child(HeroScript.new())

	_stones = Node2D.new()
	_stones.name = "Stones"
	_stones.z_index = 2
	add_child(_stones)

	_hud = HudScript.new()
	add_child(_hud)
	_hud.action_chosen.connect(_on_action)
	_hud.setup_wall(number, level["title"])
	_hud.set_wall_hp(start_hp, max_hp)
	_hud.set_coins(GameState.coins)
	GameState.coins_changed.connect(_hud.set_coins)

	if level.get("boss", false):
		_spawn_boss()
	else:
		_spawn_enemies(level)
		_hud.set_enemies(_enemy_icons(level))
	_hud.show_intro(number, level["title"], level["tip"])
	GameState.audio.play("horn")


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
		_hud.show_banner("The flagship is angry!", "Two cannons at once now.")
	else:
		_hud.show_banner("Last stand!", "Three cannons. Hold on!")


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


func _on_wave_cleared() -> void:
	for stone in get_tree().get_nodes_in_group("stones"):
		stone.shatter()
	var number := GameState.current_wall
	var bonus := GameState.wave_cleared()
	_wall.heal_full()
	GameState.audio.play("wall_held")
	_fx.float_text(Vector2(GameData.FIELD_CENTER_X, GameData.WALL_TOP - 10), "Retake bonus +%d" % bonus, FxData.COIN_COLOR)
	if GameState.is_last_wall():
		_finish("win", "Victory!", "The flagship sinks. Every wall is ours again.")
		return
	GameState.advance()
	var next := GameState.current_wall
	_continue_text = "Go to Wall %d" % next
	var repair_note := "\nIt's in ruins: you will repair it before the fight." if GameState.needs_repair() else ""
	_end("Wall %d Held!" % number,
		"Retake bonus: +%d coins.\nNext: Wall %d - %s%s" % [bonus, next, GameState.wall_title(next), repair_note],
		[["Shop", "shop", false], ["Next Wall", "next", true]])


func _on_wall_fallen() -> void:
	if _ended:
		return
	var lost := GameState.current_wall
	if lost == 1:
		_finish("lose", "The Last Wall Fell", "There is no wall left to fall back to.")
		return
	GameState.audio.play("wall_fell")
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
			# moving out to a fallen wall: repair it first (you choose how much and pay for it)
			if GameState.needs_repair():
				_hud.open_repair(_continue_text)
			else:
				_reload()
		"go":
			_reload()
		"shop":
			_hud.open_shop(_continue_text)


func _reload() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()
