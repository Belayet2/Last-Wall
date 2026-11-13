extends RefCounted
# All balance numbers and layout constants. Tune here.

# --- Layout (window is 1280x720, play field is the middle strip) ---
const FIELD_LEFT := 320.0
const FIELD_RIGHT := 960.0
const SCREEN_H := 720.0
const WALL_TOP := 640.0
const HERO_Y := 600.0
const HERO_SIZE := Vector2(30, 40)
const ENEMY_ROW_Y := 90.0
const ENEMY_ROW_Y_WITH_BOSS := 180.0
const BOSS_Y := 70.0
const OBSTACLE_SIZE := Vector2(90, 18)
const OBSTACLE_MIN_Y := 270.0
const OBSTACLE_MAX_Y := 420.0
const OBSTACLE_MAX_TILT := 35.0 # degrees

# --- Hero / shield ---
const HERO_SPEED := 220.0
const SHIELD_DISTANCE := 48.0
const SHIELD_WIDTH := 90.0
const SHIELD_THICKNESS := 12.0
const SHIELD_MIN_DEG := 10.0 # angle above horizontal
const SHIELD_MAX_DEG := 170.0
const SHIELD_FLASH_TIME := 0.15
const BASE_BOUNCE_RATE := 0.40
const BASE_AIM_ACCURACY := 0.0
const BOUNCE_SPEEDUP := 1.25

# --- Projectiles ---
const PROJECTILE_LIFETIME := 8.0
const AIM_ERROR := 0.12 # radians of random error on each throw
const WOBBLE_AMP := 60.0 # sideways px/s of the sine curve on hostile shots
const WOBBLE_FREQ := 4.0 # radians per second
const RETURN_DAMAGE := 1
const RETURN_DAMAGE_HEAVY := 3
const HOSTILE_COLOR := Color(1.0, 0.25, 0.25)
const RETURNED_COLOR := Color(0.3, 1.0, 0.4)

# --- Enemies ---
const FIRST_THROW_DELAY := 1.0
const THROW_JITTER := 0.3
const BOSS_MOVE_SPEED := 60.0
const BOSS_SHOTS := ["thrower", "fast", "heavy"] # boss picks one per throw
const ENEMIES := {
	"thrower": {"hp": 3, "interval": 2.8, "speed": 180.0, "damage": 10, "coins": 5,
		"size": Vector2(40, 40), "color": Color(0.85, 0.1, 0.1), "radius": 8.0, "heavy": false},
	"fast": {"hp": 2, "interval": 1.6, "speed": 260.0, "damage": 5, "coins": 8,
		"size": Vector2(28, 28), "color": Color(1.0, 0.55, 0.1), "radius": 6.0, "heavy": false},
	"heavy": {"hp": 5, "interval": 4.0, "speed": 120.0, "damage": 30, "coins": 12,
		"size": Vector2(56, 56), "color": Color(0.45, 0.05, 0.05), "radius": 12.0, "heavy": true},
	# Boss shots are mixed: speed/damage/radius come from BOSS_SHOTS types.
	"boss": {"hp": 40, "interval": 1.4, "speed": 0.0, "damage": 0, "coins": 100,
		"size": Vector2(140, 70), "color": Color(0.55, 0.2, 0.8), "radius": 0.0, "heavy": false},
}

# --- Walls / waves (wall 1 = innermost) ---
const FREE_WALL_HP := 20
const RETAKE_BONUS_PER_WALL := 30
const LEVELS := [
	{"wall_hp": 150, "boss": false, "obstacles": 0,
		"enemies": ["thrower", "thrower", "thrower"]},
	{"wall_hp": 120, "boss": false, "obstacles": 1,
		"enemies": ["thrower", "fast", "thrower", "fast"]},
	{"wall_hp": 100, "boss": false, "obstacles": 2,
		"enemies": ["thrower", "fast", "heavy", "fast", "thrower"]},
	{"wall_hp": 80, "boss": false, "obstacles": 3,
		"enemies": ["fast", "thrower", "heavy", "heavy", "thrower", "fast"]},
	{"wall_hp": 60, "boss": true, "obstacles": 3,
		"enemies": ["thrower", "fast", "heavy", "fast"]},
]

# --- Shop ---
const SHOP := {
	"bounce": {"name": "Bounce Rate", "step": 0.10, "costs": [20, 35, 50, 70, 90, 120]},
	"speed": {"name": "Move Speed", "step": 25.0, "costs": [15, 25, 40, 60, 80]},
	"aim": {"name": "Aim Accuracy", "step": 0.15, "costs": [30, 50, 80, 120]},
	"reinforce": {"name": "Reinforce Walls", "step": 15.0, "costs": [40, 70, 100, 140]},
}
const REPAIR_HP := 10
const REPAIR_COST_PER_HP := 2
