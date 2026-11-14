## Coins, shop and repairs. Tune freely.

const START_COINS := 0
const RETAKE_BONUS_PER_WALL := 40   # bonus = this * wall number, paid every time a wave is cleared

# --- Repairing a retaken wall (you pay before you fight on it) ---
const FALLEN_WALL_FREE_HP := 0.2    # your men patch a retaken wall to 20% for free (so you never start at 0)
const REPAIR_STEP := 0.1            # each repair step adds 10% of the wall's max HP
const REPAIR_COINS_PER_HP := 0.3    # price: a step that adds 26 HP costs ceil(26 * 0.3) = 8 coins

## "costs" has one entry per level, so its length is the max level.
const UPGRADES := {
	"shield_width": {"name": "Shield Aura", "desc": "Wider golden bounce zone", "start": 140.0, "per_level": 25.0, "costs": [20, 40, 60]},
	"move_speed": {"name": "Move Speed", "desc": "Walk faster along the path", "start": 360.0, "per_level": 40.0, "costs": [15, 30, 50]},
	"aim_assist": {"name": "Aim Assist", "desc": "Bounced stones curve more toward enemies", "start": 0.6, "per_level": 0.1, "costs": [25, 45, 70]},
	"stone_power": {"name": "Stone Power", "desc": "Bounced stones hit harder (+1 damage)", "start": 0.0, "per_level": 1.0, "costs": [40, 80]},
}
