class_name GameConfig
extends RefCounted
## Layout + general tuning numbers. Change values here, not in the logic.

# --- Play field (portrait strip in the middle of the 1280x720 window) ---
const FIELD_LEFT := 360.0
const FIELD_RIGHT := 920.0
const FIELD_TOP := 0.0
const FIELD_BOTTOM := 720.0

# --- Wall ---
const WALL_HEIGHT := 80.0            # wall sits at the bottom of the field
const WALL_CRACKED_AT := 0.66        # below this HP fraction the wall looks cracked
const WALL_BROKEN_AT := 0.33         # below this HP fraction the wall looks broken

# --- Hero + shield ---
const HERO_Y := 610.0                # fixed Y of the hero (just above the wall)
const HERO_SIZE := Vector2(48, 48)   # on-screen size of the hero sprite
const SHIELD_OFFSET_Y := -40.0       # shield sits this far above the hero
const SHIELD_WIDTH := 110.0
const SHIELD_THICKNESS := 16.0
const SHIELD_MAX_TILT_DEG := 40.0    # bounce normal tilt at the very edge of the shield
const RETURN_MAX_ANGLE_DEG := 60.0   # returned shots never fly flatter than this (from straight up)
const BOUNCE_SPEED_MULT := 1.25

# --- Starting upgrade values (the shop changes these later) ---
const START_BOUNCE_RATE := 0.40
const START_MOVE_SPEED := 220.0
const START_AIM_ACCURACY := 0.0

# --- Projectiles ---
const PROJECTILE_RADIUS := 7.0
const PROJECTILE_LIFETIME := 8.0
const THROW_ANGLE_ERROR_DEG := 6.0   # random aim error when an enemy throws

# --- Enemies ---
const ENEMY_ROW_Y := 85.0
const ENEMY_FIRST_THROW_DELAY := Vector2(0.6, 2.2)   # random range (min, max) seconds
const ENEMY_THROW_JITTER := 0.5                      # +/- seconds added to every throw interval
