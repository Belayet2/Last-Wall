## The story, told by a narrator in text (no voice). Edit the words freely.
## Each slide = one animated scene + its text. The text types out, then waits for a click / Space.
## The scenes are drawn in the game from its own pictures (scripts/ui/story_scene.gd), and they
## follow the text: things happen when the text reaches certain words (a king's name, "fell", ...).
## Want your own picture for a slide instead? Add it to art_data.gd and put its name in "image".

const TYPE_CHARS_PER_SECOND := 45.0  # how fast the text types out (click to show it all at once)
const TEXT_SIZE := 28                # story text size
const FADE_TIME := 0.8               # crossfade between slides
const ZOOM := 1.06                   # your own pictures ("image") slowly zoom in to this size

const SLIDES := [
	{
		"scene": "walls_rise",
		"text": "Long ago, the first king of our island, King Zoa, built a wall of stone on the shore to guard his small town. When the town grew, his son built a second wall behind it, and generation after generation, king after king, the kingdom grew. And so it went: five kings, five walls, each one further from the sea, until the fifth stood around the very heart of the kingdom.",
	},
	{
		"scene": "kings",
		"text": "Zoa, Vegas, Raiyon, Edmund and Aldren. For two hundred years these walls kept us safe. The people loved the wall of Zoa, the first wall. It was the oldest one. But the strongest among them was the wall of Aldren. They called it the Last Wall... If every other wall should fall, it would be the last thing standing between the sea, our home and our last hope.",
	},
	{
		"scene": "war",
		"text": "Then the raiders came from across the sea. We fought them on every wall... and we won. But victory has a price. Most of our soldiers never came home.",
	},
	{
		"scene": "sails",
		"text": "We had only just buried our brave ones when the watchmen saw sails on the horizon. More ships than before. Many more. And this time, there was no army left to stop them.",
	},
	{
		"scene": "walls_fall",
		"text": "The wall of Zoa fell first. Then the wall of Vegas, and then the wall of Raiyon. Within a week, every wall had fallen... except the Last Wall.",
	},
	{
		"scene": "king_calls",
		"text": "The old king did not call for a general. Not for an army. There was no one left. He called for one soldier, blessed with a mythical shield... \"Call the hero.\"",
	},
	{
		"scene": "hero",
		"text": "Hold the Last Wall. Take the others back, one by one. And whatever they throw at you... bounce it back.",
	},
]

const WIN := {
	"title": "Victory!",
	"portrait": "portrait_king",
	"text": "One by one, the walls were taken back. The great flagship sank beneath the waves, and the wall of Zoa, the first wall of all, is ours again. Five kings built our walls. One hero brought them home.",
}

const LOSE := {
	"title": "Defeat",
	"portrait": "portrait_commander",
	"text": "The Last Wall has fallen. But walls can be rebuilt... and heroes can rise again.",
}
