extends Node2D
## The play field: builds the world, wall, hero, enemies and HUD for the current wall.

const GameData = preload("res://scripts/data/game_data.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const ArtData = preload("res://scripts/data/art_data.gd")
const WallScript = preload("res://scripts/wall.gd")
const HeroScript = preload("res://scripts/hero.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const HudScript = preload("res://scripts/hud.gd")

var _wall: WallScript
var _hud: HudScript
var _stones: Node2D
var _markers: Node2D
var _alive := 0
var _ended := false


func _ready() -> void:
	get_tree().paused = false
	var level: Dictionary = LevelData.WALLS[GameState.current_wall - 1]
	var wall_hp: int = level["max_hp"]

	_build_world()

	_markers = Node2D.new()
	_markers.name = "Markers"
	add_child(_markers)

	_wall = WallScript.new()
	_wall.setup(wall_hp, wall_hp)
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
	_hud.restart_requested.connect(_restart)
	_hud.setup_wall(GameState.current_wall, level["title"])
	_hud.set_wall_hp(wall_hp, wall_hp)
	_hud.set_enemy_count(_alive)
	_hud.set_coins(GameState.coins)
	GameState.coins_changed.connect(_hud.set_coins)
	_hud.show_intro(GameState.current_wall, level["title"])


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


func _on_enemy_died(enemy: Node) -> void:
	var coins: int = enemy.data["coins"]
	GameState.add_coins(coins)
	_alive -= 1
	_hud.mark_enemy_down(enemy.index)
	if _alive <= 0 and not _ended:
		_end("Wall Held!", "Every thrower is down. The wall stands.", "Play again")
		for stone in get_tree().get_nodes_in_group("stones"):
			stone.remove()


func _on_wall_hp_changed(hp: int, max_hp: int) -> void:
	_hud.set_wall_hp(hp, max_hp)


func _on_wall_fallen() -> void:
	if not _ended:
		_end("Wall Fell!", "The stones broke through.", "Try again")


func _end(title: String, subtitle: String, button_text: String) -> void:
	_ended = true
	_hud.show_end(title, subtitle, button_text)
	await get_tree().create_timer(GameData.END_PAUSE_DELAY).timeout
	get_tree().paused = true


func _restart() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().reload_current_scene()
