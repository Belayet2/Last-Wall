## Enemy types. Tune freely.

const WINDUP_TIME := 0.7            # arm raise before each throw (landing marker shows during it)
const FIRST_THROW_DELAY_MIN := 1.5  # first throw comes between this and throw_interval
const RETRY_WAIT := 0.25            # wait when too many stones are already in the air
const INTERVAL_JITTER := 0.15       # +/- 15% random on each throw interval
const TARGET_EDGE_MARGIN := 60.0    # stones never aim closer than this to the field edge
const HITBOX_SCALE := 1.3           # enemies are easier to hit than they look

## "sprite" = standing pose, "windup_sprite" = about to throw.
## "hand" = where the stone leaves from, relative to the enemy center (in the windup pose).
const TYPES := {
	"thrower": {
		"hp": 2,
		"throw_interval": 3.0,
		"stone_speed": 150.0,
		"wall_damage": 8,
		"coins": 5,
		"return_damage": 1,
		"stone_size": 22.0,
		"sprite": "enemy_thrower",
		"windup_sprite": "enemy_thrower_windup",
		"hand": Vector2(14, -21),
		"size": Vector2(48, 56),
	},
	"slinger": {
		"hp": 1,
		"throw_interval": 2.2,
		"stone_speed": 200.0,
		"wall_damage": 5,
		"coins": 4,
		"return_damage": 1,
		"stone_size": 15.0,
		"sprite": "enemy_slinger",
		"windup_sprite": "enemy_slinger_windup",
		"hand": Vector2(17, -20),
		"size": Vector2(40, 48),
	},
	"catapult": {
		"hp": 4,
		"throw_interval": 5.0,
		"stone_speed": 110.0,
		"wall_damage": 20,
		"coins": 15,
		"return_damage": 2,
		"stone_size": 32.0,
		"sprite": "enemy_catapult",
		"windup_sprite": "enemy_catapult_windup",
		"hand": Vector2(32, 2),
		"size": Vector2(80, 64),
	},
}
