# Assets: how to put in your own art and sounds

Every picture and sound is a file with a fixed name. To use your own, **save your file with the same name over the old one** (same folder). You don't need to change any code. Make a backup first (commit in git, or copy the `assets` folder).

```
assets/
  sprites/
    characters/   hero, shield, shadow, enemy_cannon, enemy_slinger(+_windup), enemy_catapult(+_windup), ship
    bricks/       foundation_1..5, brick_mud, brick_clay, brick_stone, brick_marble, brick_cracks_1/2, brick_slot
    world/        sky, sea, ground, beach, path
    shots/        stone, stone_returned, cannonball
    ui/           icon_wall, icon_coin, coin_spin, icon_cannon, icon_slinger, icon_catapult
    screens/      story_throne_room, portrait_king, portrait_commander   (win / lose screens)
  audio/          all the sounds (.wav; an .ogg with the same name wins)
  CREDITS.txt     where every file came from
```

The list of every picture, its folder and the size it is shown at is `scripts/data/art_data.gd`.

## Pictures

1. Open the picture you want to change (for example `sprites/characters/hero.png`) in your art program.
2. **Paint over it at the same size.** That keeps everything lined up (see the table below).
3. **Save it as a PNG with a transparent background**, with the same name, in the same folder.
4. Switch back to Godot (it re-imports by itself) and press **F5**.

Your picture can be a different size too: it is scaled to its "shown at" size. Keep the same shape (width : height) or it looks stretched. The game uses sharp pixels ("Nearest"). For smooth, high-resolution art set **Project → Project Settings → Rendering → Textures → Canvas Textures → Default Texture Filter** to **Linear**.

Free tools: **LibreSprite**, **Pixelorama** (made with Godot), **Piskel** (in the browser). **Aseprite** is paid and the best.

| File | Shown at (px) | What it is |
|---|---|---|
| `characters/hero.png` | 80 × 104 | The hero **seen from behind**, left arm raised to hold the shield |
| `characters/shield.png` | 88 × 72 | Round shield seen from behind; drawn behind the hero's head |
| `characters/shadow.png` | 64 × 16 | Soft shadow under characters |
| `characters/enemy_cannon.png` | 120 × 60 per frame | **A strip of 8 frames side by side** (60 × 30 each, barrel pointing right): 0 idle, 1 squashed, 2–7 blast and smoke |
| `characters/enemy_slinger.png` / `_windup.png` | 40 × 48 | Slinger standing / spinning the sling |
| `characters/enemy_catapult.png` / `_windup.png` | 80 × 64 | Catapult just fired / loaded |
| `characters/ship.png` | 252 × 140 | The boss flagship, **side view, bow pointing right** |
| `bricks/foundation_1.png` … `foundation_5.png` | 64 × 22 | One brick of each wall's own stone (its last layer; the Last Wall is all foundation_1) |
| `bricks/brick_mud.png`, `brick_clay.png`, `brick_stone.png`, `brick_marble.png` | 64 × 22 | The 4 bricks you buy and lay on the wall |
| `bricks/brick_cracks_1.png`, `brick_cracks_2.png` | 64 × 22 | Crack lines drawn **on top of** a damaged brick (transparent except the lines) |
| `bricks/brick_slot.png` | 64 × 22 | Build screen: dashed outline where the next brick goes |
| `world/sky.png` | 1280 × 150 | The top of the screen on walls 1–4 (the broken wall in front of it is drawn from the bricks) |
| `world/sea.png` | 1280 × 150 | The top of the screen on wall 5: sky, sea, far ships |
| `world/ground.png` | 1280 × 400 | The field on walls 1–4 |
| `world/beach.png` | 1280 × 400 | The field on wall 5 (sea at the top, then sand) |
| `world/path.png` | 1280 × 75 | The path the hero walks on |
| `shots/stone.png` | 22 × 22 | Enemy stone (bigger for boulders, smaller for sling stones) |
| `shots/stone_returned.png` | 28 × 28 | A stone or ball after it bounced off the shield (gold) |
| `shots/cannonball.png` | 22 × 22 | Fired by the cannons and the boss |
| `ui/coin_spin.png` | 32 × 32 per frame | **A strip of 10 frames** (16 × 16 each): the spinning coin |
| `ui/icon_coin.png`, `ui/icon_wall.png` | 32 × 32, 28 × 28 | Icons |
| `ui/icon_cannon.png`, `icon_slinger.png`, `icon_catapult.png` | 37 × 26, 26 × 26, 30 × 26 | HUD enemy icons |
| `screens/story_throne_room.png` | 1280 × 720 | Win / lose screen background |
| `screens/portrait_king.png`, `portrait_commander.png` | 288 × 336 | Win (king) / lose (commander) portraits. The king is also on his throne in the story |

A picture with `"frames"` in `art_data.gd` is a strip of frames side by side: keep the same number of frames, all the same width.

### Things that must line up

| Picture | Keep this in the same place |
|---|---|
| `hero.png` + `shield.png` | The hero's **feet at the bottom edge**, centered. Keep the shield centered in its own picture (the game puts it 36 px above the hero's middle). |
| `enemy_cannon.png` | Barrel pointing **right** in every frame, cannon in the same spot. Its middle, wheel axle and muzzle are `"center"`, `"axle"` and `"muzzle"` in `scripts/data/enemy_data.gd` (pixels in one 60 × 30 frame). |
| `enemy_*_windup.png` | The stone in the raised hand: `"hand"` for that enemy in `enemy_data.gd` (pixels from the picture's center). |
| `ship.png` | **Bow pointing right**, cannon holes at the 4 `"ports"` in `enemy_data.gd` (pixels in a 180 × 100 picture). |
| bricks | Fill the whole 64 × 22 picture: bricks sit edge to edge. A dark 1-px outline keeps them apart. |
| `sky.png`, `sea.png` | The enemies stand at the bottom; the top ~80 px is behind the HUD panels. |
| `beach.png` | The ship floats on the water at the top (~60 px of sea), then sand. |

**Hitboxes don't come from the pictures**, so changing a picture never breaks the gameplay.

### Drawn from your pictures (no files of their own)

- **The broken wall on the enemy side, and every wall in the story:** made from the brick pictures.
- **The story scenes:** the bricks plus `ship`, `hero`, `shield`, `portrait_king`, `enemy_cannon`, `cannonball`, `stone_returned` and `coin_spin`.

Replace those pictures and these change with them. Want your own picture for a story slide instead? Add it to `art_data.gd` (1280 × 720) and put its name in that slide's `"image"` in `scripts/data/story_data.gd`. Keep the important things in the top 60%: the text box covers the bottom.

### Tools that made some of the art

Run them from the project folder (`godot` = your Godot exe). They save into the right folder by themselves.

| Tool | Makes |
|---|---|
| `godot --headless --path . --script res://tools/make_brick_art.gd -- --src=C:/folder/with/unzipped/packs` | The bricks, from the brick texture packs (which texture becomes which brick: `SOURCES` at the top of the tool) |
| `godot --headless --path . --script res://tools/make_cannon_coin_art.gd -- --cannon=C:/path/cannon_spritesheet.png --coin=C:/path/coin_Sheet.png` | The cannon, its icon, the cannonball and the coins |
| `godot --headless --path . --script res://tools/make_placeholder_art.gd` | Any **missing** placeholder picture (it never overwrites your art; add `-- --only=hero` to redraw one on purpose) |

## Sounds (`assets/audio/`)

1. Get your sound as **.ogg** (best, small) or **.wav**.
2. Name it like the sound you replace (e.g. `bounce.ogg`) and put it in `assets/audio/`. **An `.ogg` wins over a `.wav` with the same name.**
3. Louder / quieter: `scripts/data/audio_data.gd`.

| File | When it plays |
|---|---|
| `bounce` | A stone bounces off the shield |
| `wall_hit` / `wall_crack` | A stone hits a brick / a brick breaks |
| `enemy_hit` / `enemy_down` | A bounced stone hits an enemy / knocks it down |
| `coin` | Coins from an enemy |
| `throw` | A slinger or catapult throws |
| `tap` | A stone bounces off the screen edge |
| `click` / `buy` / `repair` | Any button / buying in the shop / laying a brick |
| `horn` | A wave starts |
| `wall_held` / `wall_fell` | Wave cleared / your wall fell |
| `victory` / `defeat` | End screens |
| `cannon` / `ship_hit` / `explosion` / `boss_horn` | A cannon fires (enemy cannons play it quieter) / the boss gets hit / a cannon or the boss blows up / the boss arrives or gets angry |

There is no music. Free sounds: **jsfxr** (sfxr.me) for retro effects, **Kenney.nl** packs (CC0). Always add what you use to `CREDITS.txt`.
