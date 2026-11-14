extends Node
## Run-wide state: coins, upgrades, which wall we defend, and every wall's HP.
## The only autoload.

signal coins_changed(coins: int)

const ShopData = preload("res://scripts/data/shop_data.gd")
const LevelData = preload("res://scripts/data/level_data.gd")

const AudioScript = preload("res://scripts/audio.gd")

const FALLEN := -1   # wall_hp value for a wall the enemy holds

var audio: AudioScript   # sound effects + music (child node, survives scene changes)

var coins := 0
var current_wall := 1
var upgrade_levels: Dictionary = {}
var wall_hp: Array[int] = []    # one entry per wall; FALLEN = held by the enemy

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


## Called when a wave starts. Returns the wall's starting HP.
## (A fallen wall that was never repaired still gets the free patch.)
func begin_wave() -> int:
	var hp := wall_hp[current_wall - 1]
	if hp == FALLEN:
		hp = repair_base_hp()
		wall_hp[current_wall - 1] = hp
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


# ---------------------------------------------------------------- repairs
# When the hero moves out to a fallen wall, he pays to repair it before the fight.
# It always gets a free patch (FALLEN_WALL_FREE_HP); every repair "step" adds REPAIR_STEP of max HP.

func needs_repair() -> bool:
	return wall_hp[current_wall - 1] == FALLEN


func repair_base_hp() -> int:
	return ceili(wall_max_hp(current_wall) * ShopData.FALLEN_WALL_FREE_HP)


func repair_step_hp() -> int:
	return ceili(wall_max_hp(current_wall) * ShopData.REPAIR_STEP)


func repair_step_cost() -> int:
	return ceili(repair_step_hp() * ShopData.REPAIR_COINS_PER_HP)


## Most steps that make sense (up to full HP).
func repair_max_steps() -> int:
	return ceili(float(wall_max_hp(current_wall) - repair_base_hp()) / repair_step_hp())


## Most steps the player can pay for right now.
func repair_affordable_steps() -> int:
	return mini(repair_max_steps(), floori(float(coins) / repair_step_cost()))


func repair_hp_for(steps: int) -> int:
	return mini(repair_base_hp() + steps * repair_step_hp(), wall_max_hp(current_wall))


func repair_cost_for(steps: int) -> int:
	return steps * repair_step_cost()


## Pays and sets the wall's starting HP. Returns false if there are not enough coins.
func repair_wall(steps: int) -> bool:
	var cost := repair_cost_for(steps)
	if steps < 0 or cost > coins:
		return false
	wall_hp[current_wall - 1] = repair_hp_for(steps)
	if cost > 0:
		add_coins(-cost)
	return true