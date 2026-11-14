## The 5 walls, built by 5 kings. Wall 1 is the innermost and strongest; Wall 5 is on the shore.
## "art"      = wall pictures (wall_N_whole / _cracked / _broken)
## "backdrop" = the enemy side at the top (the next wall in ruins, or the sea)
## "ground"   = the field between
## "tip"      = shown under the wall name when the wave starts
## "boss"     = this wall is a boss fight (see BOSS in enemy_data.gd) instead of "enemies"

const WALLS := [
	{
		"title": "The Last Wall",
		"king": "King Aldren",
		"art": "wall_1", "backdrop": "ruins_1", "ground": "ground",
		"tip": "Move with A / D or the arrow keys.  Stand on the red marks to block.",
		"max_hp": 300,
		"max_stones": 2,
		"enemies": ["thrower", "thrower", "thrower"],
	},
	{
		"title": "Berin's Wall",
		"king": "King Berin",
		"art": "wall_2", "backdrop": "ruins_2", "ground": "ground",
		"tip": "New: Slingers. Their small stones fly fast, but one hit knocks them down.",
		"max_hp": 260,
		"max_stones": 2,
		"enemies": ["thrower", "slinger", "thrower", "slinger"],
	},
	{
		"title": "Corwin's Wall",
		"king": "King Corwin",
		"art": "wall_3", "backdrop": "ruins_3", "ground": "ground",
		"tip": "New: the Catapult. Its boulders are slow but hit the wall hard. Bounce them back!",
		"max_hp": 220,
		"max_stones": 3,
		"enemies": ["thrower", "slinger", "catapult", "slinger", "thrower"],
	},
	{
		"title": "Doran's Wall",
		"king": "King Doran",
		"art": "wall_4", "backdrop": "ruins_4", "ground": "ground",
		"tip": "Two catapults this time. Keep moving!",
		"max_hp": 190,
		"max_stones": 3,
		"enemies": ["slinger", "catapult", "thrower", "thrower", "catapult", "slinger"],
	},
	{
		"title": "The Sea Wall",
		"king": "King Edmund",
		"art": "wall_5", "backdrop": "sea", "ground": "beach",
		"tip": "Bounce its cannonballs back to sink the flagship!",
		"max_hp": 180,
		"max_stones": 4,
		"boss": true,
		"enemies": [],
	},
]
