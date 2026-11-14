# CLAUDE.md — "Last Wall" (v1, fresh start)

Game jam theme: **"Bounce Back"**. Engine: **Godot 4.7.2** (`D:\Godot\Godot_v4.7.2-stable_win64.exe`), **GDScript only**.

> **This file replaces the older `../CLAUDE.md`.** Where they disagree, this file wins.
> There is no 5-hour limit. Do not read or reuse the old attempt folders (`../last_wall`, `../last_wall_web`, `../minimal`).
> **Top design goal: the game must feel EASY and FAIR.** The old versions were too hard.

---

## 0. How to work

1. Build **one step at a time** (section 9). Only do the step the user asks for.
2. After every step the project must open and run with **zero errors/warnings**. Then tell the user in 3–5 short lines what to test.
3. Keep code simple. No plugins/addons.
4. **All balance numbers live in `scripts/data/*.gd`** (or `@export`). No magic numbers in logic.
5. **All art is loaded from fixed file paths in `assets/`** so the user can replace a file with a same-named one (section 8).
6. Commit after each finished step: `git add -A && git commit -m "v1 step N: ..."`.

---

## 1. Story and goal

The war was won, but most soldiers died. Enemies came back in greater numbers and **captured all the outer walls**. Only the **innermost, strongest wall** still stands. The king calls the hero.

- The game **starts at Wall 1** (the strongest, innermost wall).
- Clearing a wall's wave means the hero **pushes out and retakes** the next wall. Outer walls are **weaker** and their enemies are **stronger**.
- **Win:** clear Wall 3.
- **Lose:** Wall 1 falls.
- **Bounce Back:** stones bounce off the shield; when a wall falls the hero bounces back to the previous wall; retaking a wall heals it to 100%.

---

## 2. Screen layout (1280×720 window, stretch `canvas_items`, aspect `keep`)

The world fills the **whole screen** (no side panels). Top to bottom:

```
 ┌───────────────────────────────────────────────────────┐
 │ [Wall 1 + HP bar]     [enemy helmets]        [coins]  │  HUD: small panels over the sky
 │  ENEMY SIDE: ruins of the captured wall, enemies in   │  enemies stand here and throw stones
 │  a row (they never advance)                           │
 │▓ FIELD: open ground, stones fly here                 ▓│  rocky edges left/right: stones bounce
 │▓ PATH: hero walks left/right (red landing marks here)▓│
 │  WALL with a DOOR (decoration only), full width       │  behind the hero
 └───────────────────────────────────────────────────────┘
```

- The hero **only moves left/right** on the path (A/D or arrows). No up/down. No shield rotation. No mouse in gameplay.
- Rocky edges on the left and right of the field are solid: stones bounce off them.
- The background is **land, not sea**: the enemies stand on the rubble of the outer wall they captured.
- **Camera:** we look over the hero's shoulder toward the enemies. The hero is seen **from behind**; enemies face us. Things near the bottom (hero) are bigger than things at the top (enemies).
- **Bright and light theme** (user request): daytime blue sky with clouds, bright green field, sandy path, light stone. UI uses light parchment panels with a warm brown border and dark brown text (colors in `scripts/ui/ui_style.gd`). Avoid dark/dusk looks.
- **HUD:** only small parchment panels along the top edge (over the sky): wall number, name and HP bar (left), one helmet icon per enemy that grays out when it falls (middle), coins (right). Wave intro title in the middle of the field at the start; pause/end messages in a centered panel with a button.

---

## 3. Visual logic (must make sense)

- **Throwables are STONES** (hard and round, so bouncing off a shield looks believable).
  - Hostile stone: gray/brown.
  - Returned stone: same stone with a **bright glow/trail** (gold) so the player sees "this one is mine now".
- **Hero:** seen from behind: helmet with plume, **blue cape** (the kingdom's color), sword in the right hand.
- **Shield:** a **normal-size round shield** (about 1.7× his shoulder width) held up in front of him with his left arm. We see its back (wood, strap, steel rim). Never make the shield look like a plank or many times bigger than the hero.
- **Shield aura:** the shield is "powerful": a thin **golden arc** above it is the real bounce zone. It explains why every stone bounces, flies back faster, and curves toward enemies. The Shield Aura upgrade makes the arc wider; the shield itself never grows.
- **Team colors:** kingdom = blue + gold (hero cape, banners on our wall). Enemies = red (tunics, banners on the ruins). Bounced stones turn gold like the aura.
- **Enemies:** stone throwers standing on rubble, facing the hero. Two poses: standing (stone held low) and **windup** (arm raised with the stone). The stone leaves from the raised hand.
  - **Slinger:** hooded, spins a sling over its head in the windup pose.
  - **Catapult:** drawn **facing the hero** with a red crewman. Windup = arm pulled back with a boulder; after firing the arm is up against the top bar and the boulder leaves from the top. Longer windup (1.1 s) and bigger landing mark.
  - Each type has its own HUD icon, and each wall's intro shows a one-line tip about its new enemy (`tip` in `level_data.gd`).
- **Wall:** 3 looks by HP: **whole** (>60%), **cracked** (>0%), **broken** (0%: rubble, hole where the door was). The door is decoration only.

---

## 4. Core mechanics

### 4.1 Hero
- Moves left/right, fixed Y on the path, clamped to the field.
- **The hero has no health.** Only the wall has health. Stones pass through the hero's body.

### 4.2 Shield (always bounces)
- `Area2D` child of the hero, never rotates. Its collision is a dome matching the golden aura arc (width = `shield_width` upgrade value).
- **Every stone that touches the aura bounces. 100% of the time. No random chance.**
- Bounce angle depends on where the stone hits (like a curved surface):
  `offset = clamp((hit_x - shield_x) / (shield_width / 2), -1, 1)`; direction = straight up rotated by `offset * max_bounce_angle` (default 45°).
- **Aim assist:** after the bounce, turn the direction toward the nearest living enemy by `aim_assist` using `lerp_angle`. Start value is generous so returned stones usually hit someone.
- Returned stone speed = hostile speed × `return_speed_mult`.
- A stone can only be bounced once per frame (flag/cooldown).

### 4.3 Stones
| | Hostile | Returned |
|---|---|---|
| Hits shield | bounces (always) | ignored |
| Hits wall | damages wall, breaks into dust | ignored |
| Hits enemy | ignored | damages enemy, breaks |
| Hits side edges | bounces | bounces |
- Moved manually with a velocity vector (`Area2D`), never `RigidBody2D`.
- Hostile stones fly **straight** (no curve) toward a chosen point on the path/wall.
- Removed when off screen or after `stone_lifetime` seconds.

### 4.4 Fairness rules (what keeps it EASY)
1. **Wind-up:** each enemy raises its arm for `windup_time` before throwing.
2. **Landing marker:** when the throw starts, a red marker appears on the path where the stone will cross. It stays until the stone arrives or is bounced.
3. **Max stones in the air** per wall (`max_stones_in_air`). Enemies take turns; an enemy waits if the cap is reached.
4. Slow stones, wide shield, fast hero, sturdy wall, low wall damage.

### 4.5 Enemies (stand still, only throw)
| Type | Walls | HP | Throw interval | Stone speed | Wall damage | Coins |
|---|---|---|---|---|---|---|
| **Stone Thrower** | 1–3 | 2 | 3.0 s | 150 | 8 | 5 |
| **Slinger** (small, quick, small stones) | 2–3 | 1 | 2.2 s | 200 | 5 | 4 |
| **Catapult** (big boulder, slow) | 3 | 4 | 5.0 s | 110 | 20 | 15 |

- Returned stone damage: 1 (returned boulder: 2), +`stone_power` upgrade.
- Each throw gets a random start delay so enemies don't sync.
- On death: pop effect, coins, tell the wave manager.

### 4.6 Wall
- `max_hp`, `hp`, look changes by HP (section 3), HP bar in HUD.
- `hp <= 0` → emit `wall_fallen`.

---

## 5. Progression (3 walls)

| Wall | Max HP | Wave | Max stones in air |
|---|---|---|---|
| 1 (innermost, strongest) | 300 | 3 Stone Throwers | 2 |
| 2 | 220 | 3 Stone Throwers + 2 Slingers | 3 |
| 3 (outermost, weakest) | 160 | 2 Stone Throwers + 2 Slingers + 1 Catapult | 3 |

```
current_wall = 1  (starts at full HP)
on wave cleared:
    wall hp = 100%
    coins += retake_bonus * current_wall        (paid EVERY time, also after a fall-back)
    if current_wall == 3: WIN
    else show choice: [Shop] or [Next Wall]     (Shop also has a Next Wall button)
    next wall starts at fallen_wall_start_hp % of its max HP (+ any Repair bought)
on wall hp 0:
    if current_wall == 1: GAME OVER
    else current_wall -= 1 (that wall keeps its HP, normally 100%)
         show choice: [Shop] or [Fight]
```
- Coins come from **killing enemies** and **retaking walls** (every time, including re-taking a wall after falling back). This is on purpose: falling back is a comeback mechanic, not a punishment.

---

## 6. Shop (game paused while open)

| Upgrade | Start | Per level | Max level | Cost per level |
|---|---|---|---|---|
| **Shield Aura** (bounce zone width) | 140 px | +25 | 3 | 20, 40, 60 |
| **Move Speed** | 360 px/s | +40 | 3 | 15, 30, 50 |
| **Aim Assist** | 0.6 | +0.1 | 3 | 25, 45, 70 |
| **Stone Power** | +0 dmg | +1 | 2 | 40, 80 |
| **Repair Next Wall** | — | +25 HP | unlimited | 15 each |

Starting coins: 0. Retake bonus: `40 × wall_number`. Free start HP on a retaken wall: 50%.
All values in `scripts/data/shop_data.gd`.

---

## 7. Screens

1. **Start menu:** title, **Play** button (first click also unlocks web audio), Quit (desktop only).
2. **Story:** 3 panels, click/Space = next, **Skip** button on every panel skips the whole story.
   1. *"The war is over. We won. But most of our soldiers did not come home."*
   2. *"My king! They are back, more of them than before. Every outer wall has fallen."*
   3. *"Only the last wall still stands. ...Call the hero."*
3. **Game.**
4. **Win:** *"The walls are ours again. The kingdom is saved."* → Main Menu (or Play again).
5. **Lose:** *"The last wall has fallen."* → Try Again / Main Menu.

- Scenes: `main.tscn` (start menu, the main scene) → `story.tscn` → `game.tscn` → `end_screen.tscn`. Pause menu has Resume / Main Menu.
- Story and end screens are in a bright throne room with pixel portraits (King, Commander, Messenger) and a parchment text box with a typewriter effect. All text is in `scripts/data/story_data.gd`. End screens show enemies defeated, coins earned, and times bounced back.

---

## 8. Art and effects

- **Claude makes placeholder art first** as PNG files (simple, readable, consistent palette). The game loads every sprite from a fixed path, so replacing art = overwriting the PNG with one of the same name (any size works; sprites are scaled to a target size set in `scripts/data/art_data.gd`).
- Files (all in `assets/sprites/`): `hero, shield, shadow, stone, stone_returned, enemy_thrower(+_windup), enemy_slinger(+_windup), enemy_catapult(+_windup), wall_whole, wall_cracked, wall_broken, ground, path, ruins, edge_rocks, marker, icon_wall, icon_coin, icon_enemy` (`.png`). The list with sizes lives in `scripts/data/art_data.gd`.
- Placeholders are drawn by `tools/make_placeholder_art.gd` (it never overwrites existing files unless run with `--force` or `--only=name`).
- `assets/README.md` explains in plain steps how to replace each file and lists its target size. List sources/licenses in `assets/CREDITS.txt`.
- **Effects (important, all numbers in `scripts/data/fx_data.gd`, code in `scripts/fx.gd`):** shield flash + spark particles on bounce, gold trail on returned stones, pulsing landing markers, "-damage" text on the wall, dust puff when a stone breaks, screen shake on wall hit, enemy knock-back + pop on death, floating "+coins" text, short hit-stop on a kill, wall crack tween. Sounds later (`.ogg`, made with jsfxr), music after the Play click.

---

## 9. Build steps (one at a time, when asked)

1. **Core loop on Wall 1:** project setup (Compatibility renderer, 1280×720, input map `move_left` A/Left, `move_right` D/Right, `pause` Esc, `GameState` autoload), placeholder art + `art_data.gd`, layout (ruins, field, path, wall with door), hero, always-bounce shield with aim assist, Stone Thrower with wind-up + landing marker + stone cap, wall with 3 looks, small HUD (wall HP, coins, enemies left), "Wall Held!" / "Wall Fell!" + click to restart.
2. **Effects pass:** all effects in section 8 (no sound yet).
3. **Progression + shop:** 3 walls, coins, retake bonus, choice screen, fall back, shop.
4. **Slinger + Catapult** and the real wave rows.
5. **Menus:** start menu, story with Skip, win/lose screens.
6. **Sound + music**, `assets/README.md` replace guide.
7. **Balance + web export** (Thread Support OFF, `build/web/index.html`, test with `python -m http.server`).
   - Done: presets "Web" and "Windows" in `export_presets.cfg`. Export: `godot --headless --path . --export-release "Web" build/web/index.html` (and `"Windows" build/windows/LastWall.exe`). itch.io zip: `build/last_wall_web.zip` (index.html at the zip root). `build/` is not in git.
   - Balance (bot tests): a decent player wins in ~3 min with no fall-backs; a casual player wins in ~5-7 min and sometimes falls back once on Wall 3. Numbers left as they are.

---

## 10. Tech rules

- Renderer **Compatibility**. GDScript only. No file saves, no networking.
- `GameState` is the only autoload (coins, upgrade levels, current wall, per-wall HP, signals). It owns the audio player as a child: `GameState.audio.play("name")`, `GameState.audio.quit_game()` (stops sounds, then quits; use it instead of `get_tree().quit()`). M mutes.
- Sounds: `assets/audio/<name>.ogg` or `.wav` (.ogg wins), list and volumes in `scripts/data/audio_data.gd`. Placeholders are synthesized by `tools/make_placeholder_audio.gd`. Replace guide: `assets/README.md`.
- Use signals between nodes (`wall_fallen`, `enemy_died`, `wave_cleared`, `coins_changed`).
- Collision layers: 1 `shield`, 2 `hostile_stone`, 3 `returned_stone`, 4 `enemy`, 5 `wall`, 6 `world_edge`.

---

## 11. Final build changes (user request, after step 7)

These replace the older rules above where they disagree.

- **No background music and no voice.** Only sound effects.
- **5 walls**, built by 5 kings (data in `scripts/data/level_data.gd`):

| Wall | Name | King | Max HP | Enemies | Look |
|---|---|---|---|---|---|
| 1 | The Last Wall | Aldren | 300 | 3 Throwers | white stone |
| 2 | Berin's Wall | Berin | 260 | 2 Throwers + 2 Slingers | sandstone |
| 3 | Corwin's Wall | Corwin | 220 | 2 Throwers + 2 Slingers + 1 Catapult | red brick |
| 4 | Doran's Wall | Doran | 190 | 2 of each type | mossy stone with ivy |
| 5 | The Sea Wall | Edmund | 180 | **Boss: The Iron Flagship** | blue-grey sea stone |

  Every wall has its own last-layer brick (`foundation_N`, see section 12). The top of the screen shows the next wall out in ruins (`ruins_N`); on wall 5 it is the sea, and the field is a beach.
- Only **3 regular enemy types** (Cannon (was Thrower, see section 13), Slinger, Catapult) + the boss.
- **Boss (wall 5, `scripts/boss.gd`, numbers in `EnemyData.BOSS` and `FxData`):** an enemy ship on the sea, side view, cannons facing the shore. It sails in (horn, shake, big name banner), then roams left/right. Before each volley it stops, glows, and red marks appear for every cannonball. Volleys are a "sweep" (balls land one after another, stepping sideways: you must move) or a "cluster" (close together: one block catches them all). At 2/3 and 1/3 HP it gets angrier (banner, more balls per volley, faster, smoke then fire). Boss HP bar replaces the enemy icons. On death: chain of explosions, it sinks, longer victory pause. Bounced cannonballs turn gold like stones.
- ~~Pay to repair~~: replaced by the brick wall (section 12).
- **Story in text, no voice** (`scripts/ui/story.gd`, text in `story_data.gd`): 7 pictures with a slow zoom and crossfade. A narrator's text types out in a large, solid parchment box at the bottom, then waits for click / Space (first click shows the whole line). Skip story button. End screens show a closing narrator line. No voice files are used.
- Balance (bot tests): a decent player wins all 5 walls in ~6 min; a casual player in ~8 min with about one fall-back. With full upgrades the boss fight lasts ~55-65 s.

---

## 12. Brick wall (user request, replaces the HP wall and pay-to-repair)

The wall works like a brick-breaker game turned upside down (`scripts/wall.gd`, numbers in `scripts/data/brick_data.gd`).

- The wall is a grid: **18 columns x 4 rows** of 64 x 22 bricks (x 64..1216, bottom at y 720), with an old-stone tower at each end.
- **Bottom row = the "last layer"** (`foundation_N` picture, `foundation_hp` per wall in `level_data.gd`: 40 / 34 / 30 / 26 / 24). It is always there when you arrive at a wall. **If ANY last-layer brick breaks, the wall falls** (fall back; Game Over on Wall 1).
- A hostile stone that gets past the shield hits the **top brick of its column** (each column is a stack). Damage = the stone's `wall_damage`. Bricks show cracks below 67% / 34% HP and break with rubble.
- **Bricks you buy** (shop, left half): Mud 8 HP / 2 coins, Clay 16 / 4, Stone 30 / 7, Marble 48 / 11. Unused bricks are kept (`GameState.bricks`). Start: 12 clay bricks (the king's gift).
- **Build screen before every fight** (`scripts/ui/build.gd`): enemies wait. Pick a brick (buttons or keys 1-4), click a column to lay it on top (max 3 on the last layer), right-click takes the top brick back into stock. Auto-build (strongest bricks where enemies aim most), Clear, Shop, Fight!. Red strips over the wall show where enemies aim; numbers show each column's total HP.
- **Enemies aim at the wall in front of them** (`aim_spread` in `enemy_data.gd`), so where you build matters. The boss fires all along the wall.
- **Wave cleared:** surviving bricks are mended to full and the wall is saved (`GameState.wall_layouts`). Moving out to the next wall: only its last layer is left, you build on it. **Wall falls:** its bricks are lost (it will be a fresh last layer next time); the previous wall still has its saved bricks.
- HUD top-left: "Last layer" bar = the weakest last-layer brick.
- Brick sprites are cut from the user's texture packs (Tempisq) by `tools/make_brick_art.gd -- --src=<folder>`; the raw packs stay outside the repo (license: no redistribution of the textures).
- Balance (bot tests): good player ~3.5 min, no falls; sloppy ~6 min, 1 fall; casual 7-10 min, 0-1 falls (usually on Wall 4's two catapults). Idle hero: Wall 1 falls after ~100 s.

---

## 13. Cannons, coins and the enemy side (user request)

- **The Thrower is now a Cannon** (`"cannon"` in `enemy_data.gd`, same balance numbers). Picture: `enemy_cannon.png`, a strip of 8 frames (60 x 30, drawn 2x) cut from the user's `cannon_spritesheet.png`: 0 idle, 2-7 blast + smoke. It faces the side it aims at, tilts down (max 0.3 rad) around its wheel axle while loading (fuse sparks, glow), fires the user's cannonball from the muzzle with a kick, then levels. When destroyed it explodes. Slinger and Catapult are unchanged.
- **Coins:** `coin_spin.png` (10 frames, from the user's `coin_Sheet.png`). The HUD coin spins when you earn coins; a spinning coin pops out of every defeated enemy and with the retake bonus. `icon_coin.png` = still frame (shop, build screen).
- **Enemy-side walls** (`ruins_1-4.png`) are drawn by `tools/make_ruins_art.gd` from the brick pictures, built like our wall: columns of bricks (40 x 14, smaller because far away) on that wall's own last layer, with breaches (one goes through the last layer: that's how it fell), chipped tops, cracks, fallen bricks in front, red banners. `sea.png` (wall 5) is unchanged.
- `ArtData` supports frame strips (`"frames"` key; `hframes` on the sprite, size = one frame).
- Tools: `make_brick_art.gd` (bricks from texture packs), `make_cannon_coin_art.gd` (cannon + coin sheets), `make_ruins_art.gd` (enemy-side walls from the bricks). After changing PNGs from a script, run `godot --headless --path . --import` before playing headless.