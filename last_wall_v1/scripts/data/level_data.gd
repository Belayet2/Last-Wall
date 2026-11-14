## The 5 walls, built by 5 kings. Wall 1 is the innermost and strongest; Wall 5 is on the shore.
## "foundation"    = picture of this wall's last layer (the bottom row of bricks)
## "foundation_hp" = HP of each brick in the last layer (if one breaks, the wall falls)
## "backdrop"      = the enemy side at the top (the next wall in ruins, or the sea)
## "ground"        = the field between
## "tip"           = shown under the wall name when the wave starts
## "boss"          = this wall is a boss fight (see BOSS in enemy_data.gd) instead of "enemies"

const WALLS := [
	{
		"title": "The Last Wall",
		"king": "King Aldren",
		"foundation": "foundation_1", "backdrop": "ruins_1", "ground": "ground",
		"tip": "Move with A / D or the arrow keys.  Stand on the red marks to block.",
		"foundation_hp": 40,
		"max_stones": 2,
		"enemies": ["cannon", "cannon", "cannon"],
	},
	{
		"title": "Berin's Wall",
		"king": "King Berin",
		"foundation": "foundation_2", "backdrop": "ruins_2", "ground": "ground",
		"tip": "New: Slingers. Their small stones fly fast, but one hit knocks them down.",
		"foundation_hp": 34,
		"max_stones": 2,
		"enemies": ["cannon", "slinger", "cannon", "slinger"],
	},
	{
		"title": "Corwin's Wall",
		"king": "King Corwin",
		"foundation": "foundation_3", "backdrop": "ruins_3", "ground": "ground",
		"tip": "New: the Catapult. Its boulders break bricks fast. Bounce them back!",
		"foundation_hp": 30,
		"max_stones": 3,
		"enemies": ["cannon", "slinger", "catapult", "slinger", "cannon"],
	},
	{
		"title": "Doran's Wall",
		"king": "King Doran",
		"foundation": "foundation_4", "backdrop": "ruins_4", "ground": "ground",
		"tip": "Two catapults this time. Keep moving!",
		"foundation_hp": 26,
		"max_stones": 3,
		"enemies": ["slinger", "catapult", "cannon", "cannon", "catapult", "slinger"],
	},
	{
		"title": "The Sea Wall",
		"king": "King Edmund",
		"foundation": "foundation_5", "backdrop": "sea", "ground": "beach",
		"tip": "Bounce its cannonballs back to sink the flagship!",
		"foundation_hp": 24,
		"max_stones": 4,
		"boss": true,
		"enemies": [],
	},
]
