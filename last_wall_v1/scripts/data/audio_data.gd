## Sound effects. Tune freely. (No music, no voice.)
## Files live in assets/audio/. For each name the game
## loads "<name>.ogg" if it exists, otherwise "<name>.wav" (or .mp3).
## To replace a sound, drop in an .ogg (or .wav) with the same name.

const FOLDER := "res://assets/audio/"
const EXTENSIONS := [".ogg", ".wav", ".mp3"]

const SFX_VOLUME_DB := -4.0
const PITCH_JITTER := 0.06          # each sound plays at a slightly random pitch (+/- 6%)
const SAME_SOUND_GAP := 0.04        # the same sound will not restart faster than this (seconds)
const CHANNELS := 12                 # how many sounds can play at once

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
	"repair": -2.0,
	"horn": -4.0,
	"wall_held": -2.0,
	"wall_fell": -2.0,
	"victory": 0.0,
	"defeat": 0.0,
	"cannon": -2.0,
	"ship_hit": -1.0,
	"explosion": 0.0,
	"boss_horn": 0.0,
	"small_cannon": -9.0,
}

## Sounds that reuse another sound's file (name -> file name).
const ALIASES := {
	"small_cannon": "cannon",
}
