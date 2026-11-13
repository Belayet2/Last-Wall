## The 3 walls. Wall 1 is the innermost and strongest. Tune freely.
## "tip" is shown under the wall name when the wave starts (teaches the new enemy).

const WALLS := [
	{
		"title": "The Last Wall",
		"tip": "Move with A / D or the arrow keys.  Stand on the red marks to block.",
		"max_hp": 300,
		"max_stones": 2,
		"enemies": ["thrower", "thrower", "thrower"],
	},
	{
		"title": "The Middle Wall",
		"tip": "New: Slingers. Their small stones fly fast, but one hit knocks them down.",
		"max_hp": 220,
		"max_stones": 3,
		"enemies": ["thrower", "slinger", "thrower", "slinger", "thrower"],
	},
	{
		"title": "The Outer Wall",
		"tip": "New: the Catapult. Its boulders are slow but hit the wall hard. Bounce them back!",
		"max_hp": 160,
		"max_stones": 3,
		"enemies": ["thrower", "slinger", "catapult", "slinger", "thrower"],
	},
]
