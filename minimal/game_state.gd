extends Node
# Autoload "GameState": coins, upgrade levels, current wall, HP of every wall.

signal coins_changed(coins: int)

const D = preload("res://data.gd")

var coins := 0
var levels := {}
var current_wall := 1
var wall_hp: Array[int] = []


func _ready() -> void:
	reset()


func reset() -> void:
	coins = 0
	levels = {"bounce": 0, "speed": 0, "aim": 0, "reinforce": 0}
	current_wall = 1
	wall_hp.clear()
	for i in D.LEVELS.size():
		wall_hp.append(0) # outer walls start fallen
	wall_hp[0] = wall_max(1)
	coins_changed.emit(coins)


func step(key: String) -> float:
	return float(D.SHOP[key]["step"])


func wall_max(n: int) -> int:
	return int(D.LEVELS[n - 1]["wall_hp"]) + int(levels["reinforce"] * step("reinforce"))


func bounce_rate() -> float:
	return minf(D.BASE_BOUNCE_RATE + levels["bounce"] * step("bounce"), 1.0)


func move_speed() -> float:
	return D.HERO_SPEED + levels["speed"] * step("speed")


func aim_accuracy() -> float:
	return D.BASE_AIM_ACCURACY + levels["aim"] * step("aim")


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)


# Returns -1 when the upgrade is maxed.
func upgrade_cost(key: String) -> int:
	var costs: Array = D.SHOP[key]["costs"]
	var lvl: int = levels[key]
	return -1 if lvl >= costs.size() else int(costs[lvl])


func buy_upgrade(key: String) -> bool:
	var cost := upgrade_cost(key)
	if cost < 0 or coins < cost:
		return false
	levels[key] += 1
	add_coins(-cost)
	return true


func repair_cost() -> int:
	return D.REPAIR_HP * D.REPAIR_COST_PER_HP


func buy_repair(n: int) -> bool:
	var cost := repair_cost()
	if coins < cost or wall_hp[n - 1] >= wall_max(n):
		return false
	wall_hp[n - 1] = mini(wall_hp[n - 1] + D.REPAIR_HP, wall_max(n))
	add_coins(-cost)
	return true
