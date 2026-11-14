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
| `cannonball.png` | 22 × 22 | The ball fired by the cannons and by the boss |
| `enemy_cannon.png` | 120 × 60 per frame | The cannon enemy. **A strip of 8 frames side by side** (60 × 30 each, barrel pointing right): 0 idle, 1 squashed, 2–7 blast and smoke |
| `enemy_slinger.png` / `_windup.png` | 40 × 48 | Slinger standing / spinning the sling |
| `enemy_catapult.png` / `_windup.png` | 80 × 64 | Catapult just fired (arm up) / loaded (arm back) |
| `ship.png` | 252 × 140 | The boss: the enemy flagship, **side view, bow pointing right**. Its cannon muzzles must stay at the same spots (see below) |
| `foundation_1.png` … `foundation_5.png` | 64 × 22 | One brick of each wall's **last layer** (the bottom row that is already there when you arrive). Also used for the towers at both ends |
| `brick_mud.png`, `brick_clay.png`, `brick_stone.png`, `brick_marble.png` | 64 × 22 | The 4 bricks you buy in the shop and lay on the wall |
| `brick_cracks_1.png`, `brick_cracks_2.png` | 64 × 22 | Cracks drawn **on top of** a damaged brick (transparent picture, only the crack lines) |
| `brick_slot.png` | 64 × 22 | Build screen: dashed outline where the next brick goes |
| `ruins_1.png` … `ruins_4.png` | 1280 × 150 | The top of the screen on walls 1–4: sky and the **next** wall out, captured and broken. Drawn from the brick pictures by `tools/make_ruins_art.gd` (run it again after you change bricks) |
| `sea.png` | 1280 × 150 | The top of the screen on wall 5: sky, sea and the far-away fleet |
| `ground.png` | 1280 × 400 | The field on walls 1–4 |
| `beach.png` | 1280 × 400 | The field on wall 5 (sea at the top, then sand) |
| `path.png` | 1280 × 75 | The dirt path the hero walks on |
| `edge_rocks.png` | 40 × 475 | Rocks at the left edge (the right edge uses it mirrored) |
| `marker.png` | 56 × 18 | Red landing mark on the path |
| `coin_spin.png` | 32 × 32 per frame | The coin: **a strip of 10 frames** (16 × 16 each) of a spinning coin. Spins in the HUD and pops out of defeated enemies |
| `icon_wall.png`, `icon_coin.png`, `icon_brick.png` | 28 × 28, 32 × 32, 26 × 26 | Icons (`icon_coin` = still coin in the shop and build screen) |
| `icon_cannon.png`, `icon_slinger.png`, `icon_catapult.png` | 37 × 26, 26 × 26, 30 × 26 | HUD enemy icons |
| `story_map.png`, `story_kings.png`, `story_field.png`, `story_ships.png`, `story_map_fallen.png`, `story_king_calls.png`, `story_hero.png` | 1280 × 720 | The 7 story pictures, in order |
| `story_throne_room.png` | 1280 × 720 | End screen background |
| `portrait_king.png`, `portrait_commander.png` | 288 × 336 | Portraits on the win (king) and lose (commander) screens |

**Boss ship cannons:** the cannonballs come out of 4 gun ports. Their positions are set in `scripts/data/enemy_data.gd` (`BOSS` → `"ports"`, in pixels of a 180 × 100 image). If your ship picture has its cannons somewhere else, change those numbers.

To change a "shown at" size, edit `scripts/data/art_data.gd`. A picture with `"frames"` there is a strip of frames side by side: keep the same number of frames, all the same width.

**Cannon and coin from your sheets:** `enemy_cannon.png`, `icon_cannon.png`, `cannonball.png`, `coin_spin.png` and `icon_coin.png` were cut out of `cannon_spritesheet.png` and `coin_Sheet.png` with:

```
godot --headless --path . --script res://tools/make_cannon_coin_art.gd -- --cannon=C:/path/cannon_spritesheet.png --coin=C:/path/coin_Sheet.png
```

**Bricks from texture packs:** the bricks were cut out of the brick texture packs (Tempisq "Brick Walls", "Old Brick", "Painted Brick") with a tool. To make them again, or from other textures, unzip the packs into one folder and run:

```
godot --headless --path . --script res://tools/make_brick_art.gd -- --src=C:/path/to/unzipped/packs
```

Which texture becomes which brick is the `SOURCES` list at the top of `tools/make_brick_art.gd`. Brick HP and prices are in `scripts/data/brick_data.gd`.

To go back to the placeholder art, delete your file and run:

```
godot --headless --path . --script res://tools/make_placeholder_art.gd
```

(It only draws files that are missing, so your own art is never overwritten.)

## Making your own art: the easy way

1. **Paint over the placeholder.** Open the existing PNG (for example `assets/sprites/hero.png`) in your art program and draw your version on top of it, at the **same size**. That keeps everything lined up: the hero's feet, the shield above his head, the bricks fitting edge to edge, the ship's cannons.
2. **Save as PNG with transparency** (no white box around characters).
3. **Save over the old file** with the same name, then switch back to Godot and press **F5**.
4. **Save a backup first.** Before replacing art, commit in git (or copy the `assets/sprites` folder) so you can always go back.

Free pixel-art tools: **Aseprite** (paid, best), **LibreSprite** (free), **Pixelorama** (free, made with Godot), **Piskel** (free, in the browser).

### Things that must line up

| Picture | What to keep in the same place |
|---|---|
| `hero.png` + `shield.png` | The hero's **feet at the bottom edge**, centered. The shield is drawn behind him, **centered 36 px above the middle of the hero picture** (the game places it, you just keep the shield centered in its own picture). |
| `enemy_cannon.png` | Barrel pointing **right** in every frame, the cannon in the same spot. Its middle, wheel axle and muzzle are `"center"`, `"axle"` and `"muzzle"` in `enemy_data.gd` (pixels in one 60 × 30 frame). It tilts around the axle and the ball leaves from the muzzle. |
| `enemy_*_windup.png` | The stone in the raised hand. If your hand is somewhere else, change `"hand"` for that enemy in `scripts/data/enemy_data.gd` (pixels from the picture's center). |
| `enemy_catapult_windup.png` | The stone leaves from the top of the arm (`"hand"` in `enemy_data.gd`). |
| `ship.png` | **Bow pointing right**, cannon holes at the 4 `"ports"` positions in `enemy_data.gd` (pixels in a 180 × 100 picture). |
| `brick_*.png`, `foundation_N.png` | Fill the whole 64 × 22 picture: bricks sit edge to edge. A dark 1-px outline keeps them apart. |
| `ruins_N.png`, `sea.png` | Enemies stand in front of the bottom ~15 px; the top ~80 px is mostly sky (the HUD panels sit there). |
| `beach.png` | The ship floats on the water at the top (~60 px of sea), then sand. |

**Hitboxes don't come from the pictures**, so changing a picture never breaks the gameplay.

### Pixel art or smooth art?

The project is set to **sharp pixels** ("Nearest" filtering), which suits pixel art. If you draw smooth, high-resolution art instead, open **Project → Project Settings → Rendering → Textures → Canvas Textures → Default Texture Filter** and set it to **Linear**, otherwise big smooth art looks jagged when scaled down.

### Story pictures

The 7 story pictures (`story_*.png`) are drawn at 640 × 360 and shown at 1280 × 720. You can draw them at either size. Keep the important things in the **top two-thirds**: the bottom third is covered by the text box.
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
| `click` / `buy` / `repair` | Any button / buying in the shop / laying a brick on the wall |
| `horn` | A wave starts |
| `wall_held` / `wall_fell` | Wave cleared / your wall fell |
| `victory` / `defeat` | End screens |
| `cannon` / `ship_hit` / `explosion` / `boss_horn` | A cannon fires (enemy cannons play it quieter) / the boss gets hit / a cannon or the boss blows up / the boss arrives or gets angry |

There is no background music. (If you want some later, it needs a small code change in `scripts/audio.gd`.)

Free sound tools: **jsfxr** (sfxr.me) for retro sound effects. Free packs: **Kenney.nl** (CC0). Always add what you use to `CREDITS.txt`.
