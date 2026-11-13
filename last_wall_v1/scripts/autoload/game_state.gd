extends Node
## Run-wide state: coins, upgrades, current wall. The only autoload.

signal coins_changed(coins: int)

const ShopData = preload("res://scripts/data/shop_data.gd")

var coins := 0
var current_wall := 1
var upgrade_levels: Dictionary = {}


func _ready() -> void:
	reset()


func reset() -> void:
	coins = ShopData.START_COINS
	current_wall = 1
	upgrade_levels.clear()
	for key in ShopData.UPGRADES:
		upgrade_levels[key] = 0
	coins_changed.emit(coins)


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)


## Current value of an upgrade (start value + levels bought).
func get_value(key: String) -> float:
	var info: Dictionary = ShopData.UPGRADES[key]
	var level: int = upgrade_levels.get(key, 0)
	return float(info["start"]) + float(info["per_level"]) * level
