extends Node
## Run-wide state: coins, upgrades, bricks, which wall we defend, and every wall's bricks.
## The only autoload.

signal coins_changed(coins: int)
signal bricks_changed

const ShopData = preload("res://scripts/data/shop_data.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const BrickData = preload("res://scripts/data/brick_data.gd")

const AudioScript = preload("res://scripts/audio.gd")

var audio: AudioScript   # sound effects (child node, survives scene changes)

var coins := 0
var current_wall := 1
var upgrade_levels: Dictionary = {}
var wall_layouts: Array = []    # one layout per wall (see "walls" below); [] = held by the enemy
var bricks: Dictionary = {}     # brick type -> how many you have (not on a wall yet)

# end-of-game info (shown on the win / lose screen)
var last_result := ""           # "win" or "lose"
var enemies_defeated := 0
var falls := 0                  # how many times the hero fell back
var coins_earned := 0


func _ready() -> void:
	audio = AudioScript.new()
	add_child(audio)
	reset()


func reset() -> void:
	coins = ShopData.START_COINS
	current_wall = 1
	last_result = ""
	enemies_defeated = 0
	falls = 0
	coins_earned = 0
	upgrade_levels.clear()
	for key in ShopData.UPGRADES:
		upgrade_levels[key] = 0
	wall_layouts.clear()
	for i in range(wall_count()):
		wall_layouts.append([])
	bricks = BrickData.START_BRICKS.duplicate()
	bricks_changed.emit()
	coins_changed.emit(coins)


func add_coins(amount: int) -> void:
	coins += amount
	if amount > 0:
		coins_earned += amount
	coins_changed.emit(coins)


# ---------------------------------------------------------------- walls
# Each wall is saved as a "layout": one Array per column, bottom brick first.
# A brick is {"type": "foundation" / "clay" / ..., "hp": int, "max": int}.
# An empty layout ([]) = the enemy holds that wall: you arrive to its last layer only.

func wall_count() -> int:
	return LevelData.WALLS.size()


func wall_title(number: int) -> String:
	return LevelData.WALLS[number - 1]["title"]


## The layout to fight on now: the saved one, or a fresh last layer (you just arrived).
func current_layout() -> Array:
	var saved: Array = wall_layouts[current_wall - 1]
	if not saved.is_empty():
		return saved.duplicate(true)
	var hp: int = LevelData.WALLS[current_wall - 1]["foundation_hp"]
	var fresh := []
	for i in range(BrickData.COLUMNS):
		fresh.append([{"type": "foundation", "hp": hp, "max": hp}])
	return fresh


## True if the hero arrives at a wall the enemy held (only the last layer is left).
func arriving_fresh() -> bool:
	return wall_layouts[current_wall - 1].is_empty()


## The wave on the current wall was cleared: every brick still standing is mended,
## the wall is saved, and the retake bonus is paid. Returns the bonus.
func wave_cleared(layout: Array) -> int:
	var saved := layout.duplicate(true)
	for column in saved:
		for brick in column:
			brick["hp"] = brick["max"]
	wall_layouts[current_wall - 1] = saved
	var bonus := ShopData.RETAKE_BONUS_PER_WALL * current_wall
	add_coins(bonus)
	return bonus


func is_last_wall() -> bool:
	return current_wall >= wall_count()


func advance() -> void:
	current_wall = mini(current_wall + 1, wall_count())


## The current wall fell (the enemy holds it again, its bricks are lost). The hero falls back one wall.
func fall_back() -> void:
	wall_layouts[current_wall - 1] = []
	current_wall = maxi(current_wall - 1, 1)
	falls += 1


# ---------------------------------------------------------------- bricks

func brick_count(type_key: String) -> int:
	return int(bricks.get(type_key, 0))


func total_bricks() -> int:
	var n := 0
	for key in bricks:
		n += int(bricks[key])
	return n


func brick_cost(type_key: String) -> int:
	return BrickData.TYPES[type_key]["cost"]


## Buys `count` bricks. Returns false if there are not enough coins.
func buy_bricks(type_key: String, count: int) -> bool:
	var cost := brick_cost(type_key) * count
	if count <= 0 or coins < cost:
		return false
	bricks[type_key] = brick_count(type_key) + count
	add_coins(-cost)
	bricks_changed.emit()
	return true


## Takes one brick out of the stock (to lay it on the wall). Returns false if there is none.
func use_brick(type_key: String) -> bool:
	if brick_count(type_key) <= 0:
		return false
	bricks[type_key] = brick_count(type_key) - 1
	bricks_changed.emit()
	return true


## Puts a brick back into the stock (taken off the wall while building).
func return_brick(type_key: String) -> void:
	bricks[type_key] = brick_count(type_key) + 1
	bricks_changed.emit()

# ---------------------------------------------------------------- upgrades

## Current value of an upgrade (start value + levels bought).
func get_value(key: String) -> float:
	var info: Dictionary = ShopData.UPGRADES[key]
	var level: int = upgrade_levels.get(key, 0)
	return float(info["start"]) + float(info["per_level"]) * level


func upgrade_max_level(key: String) -> int:
	var costs: Array = ShopData.UPGRADES[key]["costs"]
	return costs.size()


## Cost of the next level, or -1 if the upgrade is maxed.
func upgrade_cost(key: String) -> int:
	var level: int = upgrade_levels[key]
	var costs: Array = ShopData.UPGRADES[key]["costs"]
	return costs[level] if level < costs.size() else -1


func buy_upgrade(key: String) -> bool:
	var cost := upgrade_cost(key)
	if cost < 0 or coins < cost:
		return false
	upgrade_levels[key] = int(upgrade_levels[key]) + 1
	add_coins(-cost)
	return true
