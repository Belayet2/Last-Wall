class_name LevelData
extends RefCounted
## One row per wall. Index 0 = Wall 1 (innermost). More rows arrive in Step 2/4.

const WALLS := [
	{"max_hp": 150, "enemies": ["thrower", "thrower", "thrower"], "obstacles": 0},
]


static func get_wall(wall_number: int) -> Dictionary:
	return WALLS[clampi(wall_number - 1, 0, WALLS.size() - 1)]
