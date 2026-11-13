## Story text. Edit freely.

const TYPE_TIME_PER_CHAR := 0.025   # typewriter speed (seconds per letter)

## Opening story, one entry per screen. "side" = where the portrait stands.
const LINES := [
	{
		"speaker": "Commander",
		"portrait": "portrait_commander",
		"side": "left",
		"text": "The war is over. We won. But most of our soldiers did not come home.",
	},
	{
		"speaker": "Messenger",
		"portrait": "portrait_messenger",
		"side": "right",
		"text": "My king! They are back, more of them than before. Every outer wall has fallen.",
	},
	{
		"speaker": "King",
		"portrait": "portrait_king",
		"side": "left",
		"text": "Only the last wall still stands. ...Call the hero.",
	},
]

const WIN := {
	"title": "Victory!",
	"speaker": "King",
	"portrait": "portrait_king",
	"text": "The walls are ours again. The kingdom is saved.",
}

const LOSE := {
	"title": "Defeat",
	"speaker": "Commander",
	"portrait": "portrait_commander",
	"text": "The last wall has fallen.",
}
