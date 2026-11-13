extends Node
## Run-wide state: coins, upgrades, which wall we defend, and every wall's HP.
## The only autoload.

signal coins_changed(coins: int)

const ShopData = preload("res://scripts/data/shop_data.gd")
const LevelData = preload("res://scripts/data/level_data.gd")

const FALLEN := -1   # wall_hp value for a wall the enemy holds

var coins := 0
var current_wall := 1
var upgrade_levels: Dictionary = {}
var wall_hp: Array[int] = []    # one entry per wall; FALLEN = held by the enemy
var repair_hp := 0              # extra HP bought for the next wall we fight on

# end-of-game info (shown on the win / lose screen)
var last_result := ""           # "win" or "lose"
var enemies_defeated := 0
var falls := 0                  # how many times the hero fell back
var coins_earned := 0


func _ready() -> void:
	reset()


func reset() -> void:
	coins = ShopData.START_COINS
	current_wall = 1
	repair_hp = 0
	last_result = ""
	enemies_defeated = 0
	falls = 0
	coins_earned = 0
	upgrade_levels.clear()
	for key in ShopData.UPGRADES:
		upgrade_levels[key] = 0
	wall_hp.clear()
	for i in range(wall_count()):
		wall_hp.append(wall_max_hp(i + 1) if i == 0 else FALLEN)
	coins_changed.emit(coins)


func add_coins(amount: int) -> void:
	coins += amount
	if amount > 0:
		coins_earned += amount
	coins_changed.emit(coins)


# ---------------------------------------------------------------- walls

func wall_count() -> int:
	return LevelData.WALLS.size()


func wall_max_hp(number: int) -> int:
	return LevelData.WALLS[number - 1]["max_hp"]


func wall_title(number: int) -> String:
	return LevelData.WALLS[number - 1]["title"]


## HP the current wall will start the next wave with (including repairs).
func next_start_hp() -> int:
	var max_hp := wall_max_hp(current_wall)
	var hp := wall_hp[current_wall - 1]
	if hp == FALLEN:
		hp = ceili(max_hp * ShopData.FALLEN_WALL_START_HP)
	return mini(hp + repair_hp, max_hp)


## Called when a wave starts. Returns the wall's starting HP and uses up repairs.
func begin_wave() -> int:
	var hp := next_start_hp()
	wall_hp[current_wall - 1] = hp
	repair_hp = 0
	return hp


## The wave on the current wall was cleared: heal it and pay the retake bonus.
## Returns the bonus.
func wave_cleared() -> int:
	wall_hp[current_wall - 1] = wall_max_hp(current_wall)
	var bonus := ShopData.RETAKE_BONUS_PER_WALL * current_wall
	add_coins(bonus)
	return bonus


func is_last_wall() -> bool:
	return current_wall >= wall_count()


func advance() -> void:
	current_wall = mini(current_wall + 1, wall_count())


## The current wall fell. The hero falls back one wall (it keeps its HP).
func fall_back() -> void:
	wall_hp[current_wall - 1] = FALLEN
	current_wall = maxi(current_wall - 1, 1)
	falls += 1


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


func can_repair() -> bool:
	return next_start_hp() < wall_max_hp(current_wall)


func buy_repair() -> bool:
	if not can_repair() or coins < ShopData.REPAIR_COST:
		return false
	repair_hp += ShopData.REPAIR_HP
	add_coins(-ShopData.REPAIR_COST)
	return true
