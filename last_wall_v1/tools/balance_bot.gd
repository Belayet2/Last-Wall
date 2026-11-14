extends SceneTree
## Balance bot: plays the whole game by itself, fast, with no window, and prints how it went.
## Use it after you change numbers, to see if the game got easier or harder.
##
## Run from the project folder (godot = your Godot console exe):
##   godot --headless --path . --fixed-fps 60 --script res://tools/balance_bot.gd -- casual
##
## Players:  good     moves to every ball in time
##           sloppy   a bit late, a bit off (an average player)
##           casual   slow and often off (a new player)  <- the most useful one
##           idle     never moves (can the game still be lost?)
## Add a number after the player to get a different random run:  -- casual 7
##
## Between waves it builds with Auto-build, then spends half its coins on Stone Blocks and the rest
## on upgrades. It prints one line per wave and a summary at the end.

const GameData = preload("res://scripts/data/game_data.gd")
const CATCH_Y := GameData.HERO_Y + GameData.SHIELD_CENTER_Y - GameData.AURA_HEIGHT * 0.7
const BRICK_SHARE := 0.5          # part of the coins it spends on bricks
const MAX_MINUTES := 30.0         # gives up after this much game time

var mode := "casual"
var frames := 0
var wave_frames := 0
var handled_end := false
var fought := false
var waves := 0
var falls := 0
var err := {}
var broken := 0
var last_bricks := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = args[0]
	if args.size() > 1:
		seed(int(args[1]))
	print("Balance bot: player = ", mode)


func _process(delta: float) -> bool:
	frames += 1
	wave_frames += 1
	var gs = root.get_node("GameState")
	if frames == 1:
		gs.reset()
		change_scene_to_file("res://scenes/game.tscn")
		wave_frames = 0
		return false
	var game = current_scene
	if game == null or not ("_ended" in game) or game._hud == null:
		return false
	if not fought and wave_frames == 5:
		if game._hud._build:
			game._hud._build._auto_build()
			game._hud._build.fight_pressed.emit()
		last_bricks = _count_bricks(game)
		fought = true
		return false
	if not fought:
		return false
	if not game._ended:
		var n := _count_bricks(game)
		if n < last_bricks:
			broken += last_bricks - n
		last_bricks = n
		_move_hero(game, delta)
	if game._ended and not handled_end and wave_frames > 60:
		handled_end = true
		var title: String = game._hud._msg_title.text
		print("  Wall %d: %-22s %5.1f s   bricks broken: %2d   coins now: %d" % [
			_wall_of(title, gs), "'" + title + "'", wave_frames / 60.0, broken, gs.coins])
		broken = 0
		if title.begins_with("Victory") or title.begins_with("The Last Wall"):
			print("RESULT: %s   falls back: %d   time: %.1f min   upgrades: %s" % [
				"WON" if title.begins_with("Victory") else "LOST", falls, frames / 3600.0, str(gs.upgrade_levels)])
			return true
		if title.contains("Fell"):
			falls += 1
		_shop(gs)
		game._on_action("next")
		handled_end = false
		fought = false
		wave_frames = 0
		waves += 1
	if frames > 60 * 60 * MAX_MINUTES:
		print("RESULT: still playing after %d minutes (the bot cannot win or lose)" % int(MAX_MINUTES))
		return true
	return false


func _move_hero(game, delta: float) -> void:
	var hero = game._hero
	if hero == null or mode == "idle":
		return
	var best = null
	for s in get_nodes_in_group("stones"):
		if not s.returned and s.position.y < CATCH_Y - 5.0 and (best == null or s.position.y > best.position.y):
			best = s
	if best == null:
		return
	var tx: float = best.position.x + best.velocity.x * (CATCH_Y - best.position.y) / best.velocity.y
	var sp: float = hero.speed
	var id = best.get_instance_id()
	if mode == "sloppy":
		if not err.has(id):
			err[id] = randf_range(-95.0, 95.0)
		tx += err[id]
		sp *= 0.7
	elif mode == "casual":
		if not err.has(id):
			err[id] = randf_range(-130.0, 130.0)
		tx += err[id]
		sp *= 0.55
		if best.position.y < 300.0:
			sp = 0.0
	hero.position.x = move_toward(hero.position.x, tx, sp * delta)


func _shop(gs) -> void:
	var budget := int(gs.coins * BRICK_SHARE)
	while budget >= gs.brick_cost("stone") and gs.buy_bricks("stone", 1):
		budget -= gs.brick_cost("stone")
	for key in ["shield_width", "move_speed", "stone_power", "aim_assist"]:
		if gs.upgrade_cost(key) > 0 and gs.upgrade_cost(key) <= gs.coins:
			gs.buy_upgrade(key)


func _count_bricks(game) -> int:
	var n := 0
	for col in range(game._wall._layout.size()):
		n += game._wall.column_height(col)
	return n


## The wall the wave was on (the message is shown after GameState already moved on).
func _wall_of(title: String, gs) -> int:
	var parts := title.split(" ")
	if parts.size() > 1 and parts[0] == "Wall" and parts[1].is_valid_int():
		return int(parts[1])
	return gs.current_wall
