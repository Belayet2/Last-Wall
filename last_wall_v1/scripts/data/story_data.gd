## The story, told by a narrator in text (no voice). Edit freely.
## Each slide = one picture + its text. The text types out, then waits for a click / Space.

const TYPE_CHARS_PER_SECOND := 45.0  # how fast the text types out (click to show it all at once)
const TEXT_SIZE := 28                # story text size
const FADE_TIME := 0.8               # crossfade between pictures
const ZOOM := 1.06                   # pictures slowly zoom in to this size while shown

const SLIDES := [
	{
		"image": "story_map",
		"text": "Long ago, the first king of our island, King Aldren, built a wall of white stone around his small town. When the town grew, his son built a second wall beyond it. And so it went. Five kings. Five walls. Each one further out, until the fifth stood on the very edge of the sea.",
	},
	{
		"image": "story_kings",
		"text": "Aldren. Berin. Corwin. Doran. Edmund. For two hundred years their walls kept us safe. But the people loved the first wall most. The oldest. The strongest. They called it the Last Wall... because if every other wall should fall, it would be the last thing standing between the sea and our homes.",
	},
	{
		"image": "story_field",
		"text": "Then the raiders came from across the sea. We fought them on every wall... and we won. But victory has a price. Most of our soldiers never came home.",
	},
	{
		"image": "story_ships",
		"text": "We had only just buried our brave ones when the watchmen saw sails on the horizon. More ships than before. Many more. And this time, there was no army left to stop them.",
	},
	{
		"image": "story_map_fallen",
		"text": "The Sea Wall fell first. Then Doran's wall, then Corwin's, then Berin's. Within a week, only one wall still stood. The Last Wall.",
	},
	{
		"image": "story_king_calls",
		"text": "The old king did not call for a general. He did not call for an army. There was none left. He called for one soldier, with one shield. \"Call the hero.\"",
	},
	{
		"image": "story_hero",
		"text": "Hold the Last Wall. Take the others back, one by one, all the way to the sea. And whatever they throw at you... bounce it back.",
	},
]

const WIN := {
	"title": "Victory!",
	"portrait": "portrait_king",
	"text": "One by one, the walls were taken back. The great flagship sank beneath the waves, and the sea grew quiet again. Five kings built our walls. One hero brought them home.",
}

const LOSE := {
	"title": "Defeat",
	"portrait": "portrait_commander",
	"text": "The Last Wall has fallen. But walls can be rebuilt... and heroes can rise again.",
}
