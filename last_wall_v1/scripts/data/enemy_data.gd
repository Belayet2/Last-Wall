## Enemy types. Tune freely.

const WINDUP_TIME := 0.7            # arm raise before each throw
const FIRST_THROW_DELAY_MIN := 1.5  # first throw comes between this and throw_interval
const RETRY_WAIT := 0.25            # wait when too many stones are already in the air
const INTERVAL_JITTER := 0.15       # +/- 15% random on each throw interval
const TARGET_EDGE_MARGIN := 60.0    # stones never aim closer than this to the field edge
const HITBOX_SCALE := 1.3           # enemies are easier to hit than they look
## The boss on Wall 5: the enemy flagship. It sails left/right on the sea and fires cannonballs.
## It gets angrier at 2/3 and 1/3 HP (more cannonballs per volley, faster sailing).
const BOSS := {
	"name": "The Iron Flagship",
	"hp": 70,
	"coins": 100,
	"y": 134.0,                       # center of the ship on screen (it floats where the sea meets the field)
	"hitbox": Vector2(230, 90),
	"enter_time": 2.6,                # it sails in from the right during the intro
	"first_shot_delay": 2.0,
	"roam_left": 260.0,               # it sails between these x positions
	"roam_right": 1020.0,
	"ball_art": "cannonball",
	"ball_size": 22.0,                # the ball picture is 11 x 11, drawn twice as big
	"ball_speed": 175.0,
	"wall_damage": 13,
	"return_damage": 1,
	"windup": 1.0,                    # the ship glows this long before firing
	"volley_gap": 0.7,                # seconds between the cannons of one volley
	## Cannon muzzles on ship.png (pixels in the 180x100 image). The ship image is drawn bigger in game.
	"ports": [Vector2(40, 74), Vector2(70, 74), Vector2(100, 74), Vector2(130, 74)],
	"image_size": Vector2(180, 100),
	## Phase 1 starts at full HP; phase 2 below 66%; phase 3 below 33%.
	"phases": [
		{"below": 1.01, "interval": 2.2, "volley": 2, "sail_speed": 45.0},
		{"below": 0.66, "interval": 2.5, "volley": 3, "sail_speed": 70.0},
		{"below": 0.33, "interval": 2.7, "volley": 4, "sail_speed": 95.0},
	],
}

const BOSS_SWEEP_STEP := 210.0      # "sweep" volley: each ball lands this far beside the last one
const BOSS_CLUSTER_STEP := 55.0     # "cluster" volley: balls land close together (one block catches them all)


## "sprite" = standing pose, "windup_sprite" = about to throw.
## "hand" = where the stone leaves from, relative to the enemy center.
## "windup_time" = how long the enemy telegraphs (winds up / aims) before throwing.
## "icon" = HUD icon for this enemy.
## "aim_spread" = it aims at the wall up to this far left/right of where it stands
##                (the build screen shows these spots in red).
const TYPES := {
	## The cannon (replaces the old stone thrower). Its picture is one strip of 8 frames (60 x 30 each):
	## 0 idle, 1 squashed, 2-7 fire + smoke. In "anim", points are pixels in ONE frame, cannon pointing right:
	## "center" = middle of the cannon, "axle" = wheel axle (it tilts around it), "muzzle" = where the ball leaves.
	"cannon": {
		"hp": 3,
		"throw_interval": 3.0,
		"stone_speed": 150.0,
		"aim_spread": 330.0,
		"wall_damage": 8,
		"coins": 5,
		"return_damage": 1,
		"stone_size": 22.0,
		"stone_art": "cannonball",
		"sound": "small_cannon",
		"sprite": "enemy_cannon",
		"anim": {"idle": 0, "windup": 0, "fire": [2, 3, 4, 5, 6, 7], "fps": 14.0,
			"center": Vector2(23, 15), "axle": Vector2(13, 23), "muzzle": Vector2(41, 13)},
		"max_tilt": 0.3,                  # the barrel tilts down toward the target at most this much (radians)
		"icon": "icon_cannon",
		"windup_time": 0.7,
		"size": Vector2(72, 56),
	},
	"slinger": {
		"hp": 1,
		"throw_interval": 2.2,
		"stone_speed": 200.0,
		"aim_spread": 400.0,
		"wall_damage": 6,
		"coins": 4,
		"return_damage": 1,
		"stone_size": 15.0,
		"sprite": "enemy_slinger",
		"windup_sprite": "enemy_slinger_windup",
		"icon": "icon_slinger",
		"windup_time": 0.6,
		"hand": Vector2(17, -20),
		"size": Vector2(40, 48),
	},
	"catapult": {
		"hp": 4,
		"throw_interval": 5.0,
		"stone_speed": 110.0,
		"aim_spread": 240.0,
		"wall_damage": 20,
		"coins": 15,
		"return_damage": 2,
		"stone_size": 32.0,
		"sprite": "enemy_catapult",
		"windup_sprite": "enemy_catapult_windup",
		"icon": "icon_catapult",
		"windup_time": 1.1,
		"hand": Vector2(-8, -28),
		"size": Vector2(80, 64),
	},
}
