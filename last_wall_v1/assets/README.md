# How to replace the art, sounds and the narrator's voice

Every picture and sound in Last Wall is a file with a fixed name. To use your own, **save your file with the same name over the old one**. You don't need to change any code.

## Pictures (`assets/sprites/`)

1. Make or download your picture as a **PNG** (a transparent background is best for characters).
2. Name it exactly like the file you want to replace (for example `hero.png`).
3. Copy it into `assets/sprites/`, replacing the old file.
4. Open (or switch back to) Godot. It re-imports the file by itself. Press **F5** to play.

Your picture can be **any size**. The game scales it to the "shown at" size below. Keep a similar shape (width : height) or it will look stretched. Pixel art stays sharp because the project uses "Nearest" filtering.

| File | Shown at (px) | What it is |
|---|---|---|
| `hero.png` | 80 × 104 | The hero **seen from behind** (facing the enemies), left arm raised to hold the shield |
| `shield.png` | 88 × 72 | Round shield seen from behind; drawn behind the hero's head |
| `shadow.png` | 64 × 16 | Soft shadow under characters |
| `stone.png` | 22 × 22 | Enemy stone (also used bigger for boulders, smaller for sling stones) |
| `stone_returned.png` | 28 × 28 | A stone after it bounced off the shield (gold) |
| `cannonball.png` | 24 × 24 | The boss's cannonball |
| `enemy_thrower.png` / `_windup.png` | 48 × 56 | Thrower standing / arm raised to throw |
| `enemy_slinger.png` / `_windup.png` | 40 × 48 | Slinger standing / spinning the sling |
| `enemy_catapult.png` / `_windup.png` | 80 × 64 | Catapult just fired (arm up) / loaded (arm back) |
| `ship.png` | 252 × 140 | The boss: the enemy flagship, **side view, bow pointing right**. Its cannon muzzles must stay at the same spots (see below) |
| `wall_1_whole.png` … `wall_5_broken.png` | 1280 × 95 | Our wall at the bottom. **5 walls × 3 looks** (whole, cracked, broken). Keep the door in the middle |
| `ruins_1.png` … `ruins_4.png` | 1280 × 150 | The top of the screen on walls 1–4: sky and the **next** wall out, captured and in ruins |
| `sea.png` | 1280 × 150 | The top of the screen on wall 5: sky, sea and the far-away fleet |
| `ground.png` | 1280 × 400 | The field on walls 1–4 |
| `beach.png` | 1280 × 400 | The field on wall 5 (sea at the top, then sand) |
| `path.png` | 1280 × 75 | The dirt path the hero walks on |
| `edge_rocks.png` | 40 × 475 | Rocks at the left edge (the right edge uses it mirrored) |
| `marker.png` | 56 × 18 | Red landing mark on the path |
| `icon_wall.png`, `icon_coin.png` | 28 × 28, 26 × 26 | HUD icons |
| `icon_enemy.png`, `icon_slinger.png`, `icon_catapult.png` | 26 × 26 (catapult 30 × 26) | HUD enemy icons |
| `story_map.png`, `story_kings.png`, `story_field.png`, `story_ships.png`, `story_map_fallen.png`, `story_king_calls.png`, `story_hero.png` | 1280 × 720 | The 7 pictures of the narrated story, in order |
| `story_throne_room.png` | 1280 × 720 | End screen background |
| `portrait_king.png`, `portrait_commander.png`, `portrait_messenger.png` | 288 × 336 | Portraits (the king and commander appear on the end screens) |

**Boss ship cannons:** the cannonballs come out of 4 gun ports. Their positions are set in `scripts/data/enemy_data.gd` (`BOSS` → `"ports"`, in pixels of a 180 × 100 image). If your ship picture has its cannons somewhere else, change those numbers.

To change a "shown at" size, edit `scripts/data/art_data.gd`.

To go back to the placeholder art, delete your file and run:

```
godot --headless --path . --script res://tools/make_placeholder_art.gd
```

(It only draws files that are missing, so your own art is never overwritten.)

## Sounds (`assets/audio/`)

1. Get your sound as **.ogg** (best, small) or **.wav**.
2. Name it exactly like the sound you want to replace, e.g. `bounce.ogg`.
3. Copy it into `assets/audio/`. **An `.ogg` wins over a `.wav` with the same name**, so you don't even need to delete the old `.wav`.
4. Make a sound louder or quieter in `scripts/data/audio_data.gd`.

| File | When it plays |
|---|---|
| `bounce` | A stone bounces off the shield |
| `wall_hit` / `wall_crack` | A stone hits the wall / the wall cracks or breaks |
| `enemy_hit` / `enemy_down` | A bounced stone hits an enemy / knocks it down |
| `coin` | Coins from an enemy |
| `throw` | An enemy throws |
| `tap` | A stone bounces off the side rocks |
| `click` / `buy` / `repair` | Any button / buying in the shop / repairing a wall |
| `horn` | A wave starts |
| `wall_held` / `wall_fell` | Wave cleared / your wall fell |
| `victory` / `defeat` | End screens |
| `cannon` / `ship_hit` / `explosion` / `boss_horn` | The boss fires / gets hit / blows up / arrives or gets angry |

There is no background music. (If you want some later, it needs a small code change in `scripts/audio.gd`.)

## The narrator's voice (`assets/audio/voice/`)

The script to read, with the file name for every line, is in **`assets/audio/voice/NARRATION_SCRIPT.md`**.
Save each line as `narration_01.ogg` … `narration_07.ogg`, `narration_win.ogg`, `narration_lose.ogg` in that folder.
Until a file exists, the game shows the text for a few seconds instead. The on-screen text lives in `scripts/data/story_data.gd`.

Free sound tools: **jsfxr** (sfxr.me) for retro sound effects. Free packs: **Kenney.nl** (CC0). Always add what you use to `CREDITS.txt`.
