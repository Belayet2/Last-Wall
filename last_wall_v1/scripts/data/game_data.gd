## Layout and core feel numbers. Tune freely.

# --- Play field (the full 1280 width) ---
const SCREEN_WIDTH := 1280.0
const SCREEN_HEIGHT := 720.0
const FIELD_LEFT := 0.0         # stones bounce off the screen edges
const FIELD_RIGHT := 1280.0
const FIELD_CENTER_X := 640.0

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
const HERO_Y := 571.0           # center of the hero sprite (feet on the path)
const HERO_SHADOW_Y := 48.0     # shadow under the hero's feet (relative to the hero)

# --- Shield and its golden aura (the aura is the bounce zone) ---
const SHIELD_CENTER_Y := -36.0  # shield center relative to the hero
const AURA_HEIGHT := 42.0       # how far the aura arc rises above the shield center
const AURA_THICKNESS := 10.0    # collision thickness under the arc ends
const AURA_POINTS := 24
const AURA_COLOR := Color(1.0, 0.84, 0.35)
const AURA_ALPHA := 0.6
const AURA_WIDTH := 3.0
const AURA_GLOW_WIDTH := 12.0
const AURA_GLOW_ALPHA := 0.2

const MAX_BOUNCE_ANGLE_DEG := 45.0   # edge hit tilts the bounce this much
const RETURN_SPEED_MULT := 1.6       # returned stone speed = hostile speed * this

# --- Hero feel ---
const HERO_LEAN := 0.06              # little lean when walking (radians)
const HERO_BOB := 2.0                # walking bob height (px)
const HERO_BOB_SPEED := 14.0

# --- Stones ---
const STONE_LIFETIME := 8.0
const STONE_SPIN := 6.0              # visual spin speed (radians/second)

# --- Wave intro and end ---
const INTRO_HOLD := 1.8              # seconds the "WALL 1" title stays
const INTRO_FADE := 0.6
const END_PAUSE_DELAY := 0.5         # seconds before the game freezes after win/lose
const FINISH_DELAY := 1.8            # seconds the "Victory!" / "Last Wall Fell" title shows before the end screen
const FINISH_DELAY_BOSS := 3.2       # longer after the boss, so you can watch the flagship sink
