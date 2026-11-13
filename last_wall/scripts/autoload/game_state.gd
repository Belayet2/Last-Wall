extends Node
## The only autoload. Holds run state (coins, upgrades, current wall).

signal coins_changed(coins: int)

var coins := 0
var current_wall := 1

# Upgradeable stats (the shop in Step 2 will change these).
var bounce_rate := GameConfig.START_BOUNCE_RATE
var move_speed := GameConfig.START_MOVE_SPEED
var aim_accuracy := GameConfig.START_AIM_ACCURACY


func reset() -> void:
	coins = 0
	current_wall = 1
	bounce_rate = GameConfig.START_BOUNCE_RATE
	move_speed = GameConfig.START_MOVE_SPEED
	aim_accuracy = GameConfig.START_AIM_ACCURACY
	coins_changed.emit(coins)


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)
