## Coins and shop. Tune freely. (Brick prices are in brick_data.gd.)

const START_COINS := 0
const RETAKE_BONUS_PER_WALL := 40   # bonus = this * wall number, paid every time a wave is cleared
const BRICK_BUY_MANY := 5           # the shop's second buy button buys this many bricks

## "costs" has one entry per level, so its length is the max level.
const UPGRADES := {
	"shield_width": {"name": "Shield Aura", "desc": "Wider golden bounce zone", "start": 140.0, "per_level": 25.0, "costs": [20, 40, 60]},
	"move_speed": {"name": "Move Speed", "desc": "Walk faster along the path", "start": 360.0, "per_level": 40.0, "costs": [15, 30, 50]},
	"aim_assist": {"name": "Aim Assist", "desc": "Bounced stones curve more toward enemies", "start": 0.6, "per_level": 0.1, "costs": [25, 45, 70]},
	"stone_power": {"name": "Stone Power", "desc": "Bounced stones hit harder (+1 damage)", "start": 0.0, "per_level": 1.0, "costs": [40, 80]},
}
