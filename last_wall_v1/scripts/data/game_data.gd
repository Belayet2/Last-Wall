## Layout and core feel numbers. Tune freely.

# --- Play field (x range inside the 1280 wide window) ---
const FIELD_LEFT := 260.0
const FIELD_RIGHT := 1020.0
const FIELD_CENTER_X := (FIELD_LEFT + FIELD_RIGHT) / 2.0

# --- Rows from top to bottom ---
const RUINS_TOP := 0.0
const RUINS_HEIGHT := 150.0
const GROUND_TOP := 150.0
const GROUND_HEIGHT := 400.0
const PATH_TOP := 550.0
const PATH_HEIGHT := 75.0
const WALL_TOP := 625.0
const WALL_HEIGHT := 95.0

const ENEMY_Y := 112.0          # center of the enemy row
const HERO_Y := 590.0           # center of the hero sprite

# --- Hero and shield ---
const SHIELD_OFFSET_Y := -42.0  # shield center relative to hero center
const SHIELD_Y := HERO_Y + SHIELD_OFFSET_Y
const SHIELD_HEIGHT := 16.0     # collision height
const SHIELD_SPRITE_HEIGHT := 24.0
const MAX_BOUNCE_ANGLE_DEG := 45.0   # edge hit tilts the bounce this much
const RETURN_SPEED_MULT := 1.6       # returned stone speed = hostile speed * this
const HERO_LEAN := 0.08              # little lean when walking (radians)

# --- Stones ---
const STONE_LIFETIME := 8.0
const STONE_SPIN := 6.0              # visual spin speed (radians/second)

# --- Wall looks ---
const WALL_CRACKED_BELOW := 0.6      # under 60% HP the wall looks cracked

# --- End of wave ---
const END_PAUSE_DELAY := 0.5         # seconds before the game freezes after win/lose
