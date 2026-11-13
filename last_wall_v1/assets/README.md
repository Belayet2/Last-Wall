# How to replace the art and sounds

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
| `enemy_thrower.png` / `enemy_thrower_windup.png` | 48 × 56 | Thrower standing / arm raised to throw |
| `enemy_slinger.png` / `enemy_slinger_windup.png` | 40 × 48 | Slinger standing / spinning the sling |
| `enemy_catapult.png` / `enemy_catapult_windup.png` | 80 × 64 | Catapult just fired (arm up) / loaded (arm back) |
| `wall_whole.png`, `wall_cracked.png`, `wall_broken.png` | 1280 × 95 | Our wall at the bottom, 3 damage states (keep the door in the middle) |
| `ground.png` | 1280 × 400 | The field the stones fly over |
| `path.png` | 1280 × 75 | The dirt path the hero walks on |
| `ruins.png` | 1280 × 150 | The top: sky and the ruined wall the enemies stand on |
| `edge_rocks.png` | 40 × 475 | Rocks at the left edge (the right edge uses it mirrored) |
| `marker.png` | 56 × 18 | Red landing mark on the path |
| `icon_wall.png`, `icon_coin.png` | 28 × 28, 26 × 26 | HUD icons |
| `icon_enemy.png`, `icon_slinger.png`, `icon_catapult.png` | 26 × 26 (catapult 30 × 26) | HUD enemy icons |
| `story_throne_room.png` | 1280 × 720 | Story and end screen background |
| `portrait_king.png`, `portrait_commander.png`, `portrait_messenger.png` | 288 × 336 | Story portraits (head and shoulders) |

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
| `click` / `buy` | Any button / buying in the shop |
| `horn` | A wave starts |
| `wall_held` / `wall_fell` | Wave cleared / your wall fell |
| `victory` / `defeat` | End screens |
| `music_loop` | Background music (loops; keep it under about 1.5 MB) |

Free sound tools: **jsfxr** (sfxr.me) for retro sound effects. Free packs: **Kenney.nl** (CC0). Always add what you use to `CREDITS.txt`.
