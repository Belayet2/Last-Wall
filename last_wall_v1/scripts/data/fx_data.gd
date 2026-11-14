## Effect ("juice") numbers. Tune freely. Set an amount to 0 to turn an effect off.

# --- Screen shake (pixels; it fades out at SHAKE_DECAY pixels per second) ---
const SHAKE_DECAY := 30.0
const SHAKE_WALL_HIT := 5.0
const SHAKE_WALL_CRACK := 12.0      # a brick of the last layer breaks (the wall falls)
const SHAKE_BRICK_BREAK := 7.0      # one of your bricks breaks
const SHAKE_ENEMY_DOWN := 4.0
const SHAKE_SMALL_CANNON := 1.5     # an enemy cannon fires

# --- Hit-stop: the game almost freezes for a moment when an enemy falls ---
const HIT_STOP_TIME := 0.06         # real seconds
const HIT_STOP_SCALE := 0.05        # game speed during the hit-stop

# --- Floating text ("+5" coins, "-8" wall damage) ---
const FLOAT_TEXT_RISE := 42.0
const FLOAT_TEXT_TIME := 0.8
const FLOAT_TEXT_SIZE := 22
const COIN_COLOR := Color(1.0, 0.84, 0.3)
const DAMAGE_COLOR := Color(1.0, 0.38, 0.32)
const COIN_TEXT_OFFSET_Y := 10.0    # coin text starts a bit below the enemy (stays under the HUD)
const WALL_HIT_FLASH := Color(1.3, 0.85, 0.8)

# --- Small motions ---
const KNOCKBACK := 10.0             # enemy is pushed back (up) this far when hit
const KNOCKBACK_TIME := 0.2
const SHIELD_NUDGE := 3.0           # shield dips this far when a stone hits it
const WALL_JIGGLE := 3.0            # wall shakes sideways this far when hit
const COIN_PUNCH := 1.35            # HUD coin number pops to this size

# --- Particle bursts (little pixel squares) ---
## Keys: amount, lifetime, direction, spread (deg), speed_min/max, gravity, damping,
## size_min/max (px), color. Optional: rect (emit from a box of this half-size).
const SPARKS := {
	"amount": 16, "lifetime": 0.4, "direction": Vector2(0, -1), "spread": 70.0,
	"speed_min": 120.0, "speed_max": 260.0, "gravity": Vector2(0, 520), "damping": 0.0,
	"size_min": 2.0, "size_max": 4.0, "color": Color(1.0, 0.86, 0.4),
}
const DUST := {
	"amount": 12, "lifetime": 0.5, "direction": Vector2(0, -1), "spread": 180.0,
	"speed_min": 30.0, "speed_max": 90.0, "gravity": Vector2(0, 0), "damping": 100.0,
	"size_min": 3.0, "size_max": 6.0, "color": Color(0.78, 0.72, 0.64),
}
const SMALL_DUST := {
	"amount": 5, "lifetime": 0.35, "direction": Vector2(0, -1), "spread": 180.0,
	"speed_min": 20.0, "speed_max": 60.0, "gravity": Vector2(0, 0), "damping": 90.0,
	"size_min": 2.0, "size_max": 4.0, "color": Color(0.7, 0.66, 0.6),
}
const GOLD_CHIPS := {
	"amount": 10, "lifetime": 0.45, "direction": Vector2(0, -1), "spread": 180.0,
	"speed_min": 80.0, "speed_max": 180.0, "gravity": Vector2(0, 420), "damping": 0.0,
	"size_min": 2.0, "size_max": 3.0, "color": Color(1.0, 0.82, 0.35),
}
const ENEMY_BURST := {
	"amount": 22, "lifetime": 0.6, "direction": Vector2(0, -1), "spread": 180.0,
	"speed_min": 60.0, "speed_max": 170.0, "gravity": Vector2(0, 380), "damping": 20.0,
	"size_min": 2.0, "size_max": 5.0, "color": Color(0.72, 0.2, 0.2),
}
const WALL_RUBBLE := {
	"amount": 40, "lifetime": 0.7, "direction": Vector2(0, -1), "spread": 50.0,
	"speed_min": 60.0, "speed_max": 160.0, "gravity": Vector2(0, 400), "damping": 10.0,
	"size_min": 3.0, "size_max": 6.0, "color": Color(0.62, 0.58, 0.52),
	"rect": Vector2(600, 4),
}
## Enemy cannon: the fuse is lit (windup) and the shot.
const FUSE_SPARK := {
	"amount": 8, "lifetime": 0.35, "direction": Vector2(0, -1), "spread": 60.0,
	"speed_min": 30.0, "speed_max": 80.0, "gravity": Vector2(0, 200), "damping": 0.0,
	"size_min": 2.0, "size_max": 3.0, "color": Color(1.0, 0.75, 0.25),
}
const SMALL_MUZZLE_FLASH := {
	"amount": 10, "lifetime": 0.2, "direction": Vector2(0, 1), "spread": 35.0,
	"speed_min": 60.0, "speed_max": 150.0, "gravity": Vector2(0, 0), "damping": 200.0,
	"size_min": 2.0, "size_max": 4.0, "color": Color(1.0, 0.8, 0.3),
}
## A brick breaks (its color is set from brick_data.gd).
const BRICK_RUBBLE := {
	"amount": 18, "lifetime": 0.6, "direction": Vector2(0, -1), "spread": 70.0,
	"speed_min": 60.0, "speed_max": 150.0, "gravity": Vector2(0, 420), "damping": 10.0,
	"size_min": 3.0, "size_max": 6.0, "color": Color(0.7, 0.3, 0.22),
	"rect": Vector2(26, 6),
}
## Trail behind a returned (gold) stone.
const TRAIL := {
	"amount": 18, "lifetime": 0.3, "size_min": 2.0, "size_max": 4.0, "color": Color(1.0, 0.82, 0.3),
}

# ---------------------------------------------------------------- boss (Wall 5)
const SHAKE_CANNON := 3.0
const SHAKE_BOSS_BOOM := 10.0
const SHAKE_BOSS_ARRIVE := 8.0
const BOSS_EXPLOSIONS := 6           # explosions on the flagship before it sinks
const BOSS_EXPLOSION_GAP := 0.3
const BOSS_SINK_TIME := 1.8

const PORT_GLOW := {
	"amount": 10, "lifetime": 0.6, "direction": Vector2(0, -1), "spread": 180.0,
	"speed_min": 10.0, "speed_max": 40.0, "gravity": Vector2(0, -20), "damping": 10.0,
	"size_min": 2.0, "size_max": 4.0, "color": Color(1.0, 0.55, 0.15),
}
const MUZZLE_FLASH := {
	"amount": 18, "lifetime": 0.25, "direction": Vector2(0, 1), "spread": 40.0,
	"speed_min": 80.0, "speed_max": 200.0, "gravity": Vector2(0, 0), "damping": 200.0,
	"size_min": 3.0, "size_max": 6.0, "color": Color(1.0, 0.8, 0.3),
}
const CANNON_SMOKE := {
	"amount": 14, "lifetime": 0.9, "direction": Vector2(0, -1), "spread": 120.0,
	"speed_min": 20.0, "speed_max": 60.0, "gravity": Vector2(0, -30), "damping": 30.0,
	"size_min": 5.0, "size_max": 10.0, "color": Color(0.85, 0.85, 0.85, 0.8),
}
const WOOD_CHIPS := {
	"amount": 14, "lifetime": 0.6, "direction": Vector2(0, -1), "spread": 160.0,
	"speed_min": 80.0, "speed_max": 200.0, "gravity": Vector2(0, 420), "damping": 0.0,
	"size_min": 2.0, "size_max": 4.0, "color": Color(0.55, 0.36, 0.2),
}
const EXPLOSION := {
	"amount": 40, "lifetime": 0.7, "direction": Vector2(0, -1), "spread": 180.0,
	"speed_min": 80.0, "speed_max": 260.0, "gravity": Vector2(0, 200), "damping": 60.0,
	"size_min": 4.0, "size_max": 9.0, "color": Color(1.0, 0.6, 0.15),
}
const SPLASH := {
	"amount": 60, "lifetime": 1.0, "direction": Vector2(0, -1), "spread": 60.0,
	"speed_min": 100.0, "speed_max": 260.0, "gravity": Vector2(0, 400), "damping": 10.0,
	"size_min": 3.0, "size_max": 6.0, "color": Color(0.85, 0.95, 1.0),
	"rect": Vector2(120, 6),
}
## Story scenes: smaller versions (walls and ships are far away there).
const WALL_RUBBLE_SMALL := {
	"amount": 24, "lifetime": 0.7, "direction": Vector2(0, -1), "spread": 60.0,
	"speed_min": 40.0, "speed_max": 110.0, "gravity": Vector2(0, 380), "damping": 10.0,
	"size_min": 2.0, "size_max": 4.0, "color": Color(0.62, 0.58, 0.52),
	"rect": Vector2(40, 30),
}
const EXPLOSION_SMALL := {
	"amount": 22, "lifetime": 0.5, "direction": Vector2(0, -1), "spread": 180.0,
	"speed_min": 50.0, "speed_max": 150.0, "gravity": Vector2(0, 150), "damping": 60.0,
	"size_min": 3.0, "size_max": 6.0, "color": Color(1.0, 0.6, 0.15),
}
## Continuous smoke / fire on the damaged flagship.
const SHIP_SMOKE := {
	"amount": 24, "lifetime": 1.4, "size_min": 5.0, "size_max": 10.0,
	"speed_min": 20.0, "speed_max": 50.0, "color": Color(0.5, 0.5, 0.52, 0.7),
}
const SHIP_FIRE := {
	"amount": 30, "lifetime": 0.5, "size_min": 3.0, "size_max": 6.0,
	"speed_min": 30.0, "speed_max": 70.0, "color": Color(1.0, 0.55, 0.1),
}
