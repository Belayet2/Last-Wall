## Sounds and music. Tune freely.
## Files live in assets/audio/. For each name the game loads "<name>.ogg" if it exists,
## otherwise "<name>.wav". So to replace a sound, drop in an .ogg (or .wav) with the same name.

const FOLDER := "res://assets/audio/"
const EXTENSIONS := [".ogg", ".wav", ".mp3"]

const MUSIC := "music_loop"
const MUSIC_VOLUME_DB := -12.0
const SFX_VOLUME_DB := -4.0
const PITCH_JITTER := 0.06          # each sound plays at a slightly random pitch (+/- 6%)
const SAME_SOUND_GAP := 0.04        # the same sound will not restart faster than this (seconds)
const VOICES := 10                  # how many sounds can play at once

## name -> extra volume in dB (0 = normal, negative = quieter)
const SOUNDS := {
	"bounce": 0.0,
	"wall_hit": 0.0,
	"wall_crack": 2.0,
	"enemy_hit": -2.0,
	"enemy_down": 0.0,
	"coin": -4.0,
	"throw": -12.0,
	"tap": -10.0,
	"click": -6.0,
	"buy": -2.0,
	"horn": -4.0,
	"wall_held": -2.0,
	"wall_fell": -2.0,
	"victory": 0.0,
	"defeat": 0.0,
}
