## Coins and shop. Tune freely. (The shop screen comes in step 3.)

const START_COINS := 0
const RETAKE_BONUS_PER_WALL := 40   # bonus = this * wall number, paid every time
const FALLEN_WALL_START_HP := 0.5   # a retaken wall starts at 50% HP
const REPAIR_HP := 25
const REPAIR_COST := 15

const UPGRADES := {
	"shield_width": {"name": "Shield Width", "start": 150.0, "per_level": 25.0, "costs": [20, 40, 60]},
	"move_speed": {"name": "Move Speed", "start": 300.0, "per_level": 40.0, "costs": [15, 30, 50]},
	"aim_assist": {"name": "Aim Assist", "start": 0.6, "per_level": 0.1, "costs": [25, 45, 70]},
	"stone_power": {"name": "Stone Power", "start": 0.0, "per_level": 1.0, "costs": [40, 80]},
}
