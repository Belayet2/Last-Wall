## The brick wall (works like a brick-breaker game, upside down). Tune freely.
##
## The wall is a grid of bricks: COLUMNS side by side, ROWS high.
## The bottom row is the "last layer" (the foundation). It is always there when you arrive.
## You build the rows above it with bricks you bought. A stone that gets past your shield
## hits the TOP brick of its column. If ANY brick of the last layer breaks, the wall falls.

# --- Grid (pixels on screen) ---
const COLUMNS := 18
const COLUMN_LEFT := 64.0           # x of the first column (a tower stands on each side)
const BRICK_W := 64.0
const BRICK_H := 22.0
const ROWS := 4                     # 1 last layer + 3 rows you build
const BOTTOM := 720.0               # bottom edge of the last layer

# --- Looks ---
const CRACK_1_BELOW := 0.67         # under 67% HP a brick shows small cracks
const CRACK_2_BELOW := 0.34         # under 34% HP: big cracks
const DROP_HEIGHT := 26.0           # a placed brick drops in from this high
const DANGER_COLOR := Color(0.9, 0.2, 0.15)
const DANGER_ALPHA_MAX := 0.85      # build screen: red strip over the columns enemies aim at most

# --- Bricks you start the game with (a gift from the king) ---
const START_BRICKS := {"clay": 12}

## Bricks you can buy. "hp" = how much damage it takes before it breaks.
## A thrower's stone does 8, a slinger's 5, a catapult boulder 20, a cannonball 12.
const ORDER := ["mud", "clay", "stone", "marble"]
const TYPES := {
	"mud": {"name": "Mud Brick", "desc": "Cheap, but one stone breaks it", "hp": 8, "cost": 2,
		"art": "brick_mud", "color": Color(0.8, 0.5, 0.28)},
	"clay": {"name": "Clay Brick", "desc": "A good, normal brick", "hp": 16, "cost": 4,
		"art": "brick_clay", "color": Color(0.7, 0.3, 0.22)},
	"stone": {"name": "Stone Block", "desc": "Strong. Takes 4 stones", "hp": 30, "cost": 7,
		"art": "brick_stone", "color": Color(0.55, 0.55, 0.55)},
	"marble": {"name": "Marble Block", "desc": "The strongest. Takes 6 stones", "hp": 48, "cost": 11,
		"art": "brick_marble", "color": Color(0.92, 0.9, 0.86)},
}
