## The 5 walls. Five kings built them, from the sea inland: Zoa's wall stands on the shore,
## Aldren's, the strongest, is the Last Wall in front of our home. The game starts at the Last Wall
## and you fight your way back out to the sea.
## "foundation"    = picture of this wall's bricks (its last layer, the bottom row)
## "foundation_hp" = HP of each brick in the last layer (if one breaks, the wall falls)
## "prebuilt_hp"   = the wall is already whole (all rows, its own stone, this HP each): you don't build on it
## "far_wall"      = the enemy side shows the next wall out (this picture), broken. No far_wall = open sea.
## "backdrop"      = sky behind the enemy side ("sky", or "sea" on the shore)
## "ground"        = the field between
## "tip"           = shown under the wall name when the wave starts
## "boss"          = this wall is a boss fight (see BOSS in enemy_data.gd) instead of "enemies"

const WALLS := [
	{
		"title": "The Last Wall",
		"king": "King Aldren",
		"foundation": "foundation_1", "backdrop": "sky", "far_wall": "foundation_2", "ground": "ground",
		"tip": "Move with A / D or the arrow keys.  Stand on the red marks to block.",
		"foundation_hp": 40,
		"prebuilt_hp": 20,
		"max_stones": 2,
		"enemies": ["cannon", "cannon", "cannon"],
	},
	{
		"title": "The Wall of Edmund",
		"king": "King Edmund",
		"foundation": "foundation_2", "backdrop": "sky", "far_wall": "foundation_3", "ground": "ground",
		"tip": "New: Slingers. Their small stones fly fast, but one hit knocks them down.",
		"foundation_hp": 34,
		"max_stones": 2,
		"enemies": ["cannon", "slinger", "cannon", "slinger"],
	},
	{
		"title": "The Wall of Raiyon",
		"king": "King Raiyon",
		"foundation": "foundation_3", "backdrop": "sky", "far_wall": "foundation_4", "ground": "ground",
		"tip": "New: the Catapult. Its boulders break bricks fast. Bounce them back!",
		"foundation_hp": 30,
		"max_stones": 3,
		"enemies": ["cannon", "slinger", "catapult", "slinger", "cannon"],
	},
	{
		"title": "The Wall of Vegas",
		"king": "King Vegas",
		"foundation": "foundation_4", "backdrop": "sky", "far_wall": "foundation_5", "ground": "ground",
		"tip": "Two catapults this time. Keep moving!",
		"foundation_hp": 26,
		"max_stones": 3,
		"enemies": ["slinger", "catapult", "cannon", "cannon", "catapult", "slinger"],
	},
	{
		"title": "The Wall of Zoa",
		"king": "King Zoa",
		"foundation": "foundation_5", "backdrop": "sea", "ground": "beach",
		"tip": "The first wall of all, on the shore. Bounce the cannonballs back to sink the flagship!",
		"foundation_hp": 24,
		"max_stones": 4,
		"boss": true,
		"enemies": [],
	},
]
