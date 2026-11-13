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

Top to bottom:

```
 ┌───────────────────────────────────────────┐
 │  ENEMY SIDE: ruins of the captured wall,  │  enemies stand here and throw stones
 │  enemies in a row (they never advance)    │
 ├───────────────────────────────────────────┤
 │  FIELD: open ground, stones fly here      │  landing markers show on the path
 ├───────────────────────────────────────────┤
 │  PATH: hero walks left/right with shield  │
 ├───────────────────────────────────────────┤
 │  WALL with a DOOR (decoration only)       │  full width, behind the hero
 └───────────────────────────────────────────┘
```

- The hero **only moves left/right** on the path (A/D or arrows). No up/down. No shield rotation. No mouse in gameplay.
- Left and right screen edges are solid: stones bounce off them.
- The background is **land, not sea**: the enemies stand on the rubble of the outer wall they captured.

---

## 3. Visual logic (must make sense)

- **Throwables are STONES** (hard and round, so bouncing off a shield looks believable).
  - Hostile stone: gray/brown.
  - Returned stone: same stone with a **bright glow/trail** (gold) so the player sees "this one is mine now".
- **Shield:** a big round/kite shield held **above the hero's head**, a bit wider than the hero.
- **Enemies:** stone throwers standing on rubble. They **wind up** (raise an arm) before every throw.
- **Wall:** 3 looks by HP: **whole** (>60%), **cracked** (>0%), **broken** (0%: rubble, hole where the door was). The door is decoration only.

---

## 4. Core mechanics

### 4.1 Hero
- Moves left/right, fixed Y on the path, clamped to the field.
- **The hero has no health.** Only the wall has health. Stones pass through the hero's body.

### 4.2 Shield (always bounces)
- Flat paddle `Area2D` above the hero, child of the hero, never rotates.
- **Every stone that touches the shield bounces. 100% of the time. No random chance.**
- Bounce angle depends on where the stone hits the shield:
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
| **Shield Width** | 150 px | +25 | 3 | 20, 40, 60 |
| **Move Speed** | 300 px/s | +40 | 3 | 15, 30, 50 |
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
4. **Win:** *"The walls are ours again. The kingdom is saved."* → Main Menu.
5. **Lose:** *"The last wall has fallen."* → Try Again / Main Menu.

---

## 8. Art and effects

- **Claude makes placeholder art first** as PNG files (simple, readable, consistent palette). The game loads every sprite from a fixed path, so replacing art = overwriting the PNG with one of the same name (any size works; sprites are scaled to a target size set in `scripts/data/art_data.gd`).
- Files: `assets/sprites/hero.png, shield.png, stone.png, stone_returned.png, enemy_thrower.png, enemy_slinger.png, enemy_catapult.png, wall_whole.png, wall_cracked.png, wall_broken.png, ground.png, ruins.png, marker.png`.
- `assets/README.md` explains in plain steps how to replace each file and lists its target size. List sources/licenses in `assets/CREDITS.txt`.
- **Effects (important):** shield flash + spark particles on bounce, dust puff when a stone breaks, screen shake on wall hit, enemy knock-back + pop on death, floating "+coins" text, short hit-stop on a kill, wall crack tween. Sounds later (`.ogg`, made with jsfxr), music after the Play click.

---

## 9. Build steps (one at a time, when asked)

1. **Core loop on Wall 1:** project setup (Compatibility renderer, 1280×720, input map `move_left` A/Left, `move_right` D/Right, `pause` Esc, `GameState` autoload), placeholder art + `art_data.gd`, layout (ruins, field, path, wall with door), hero, always-bounce shield with aim assist, Stone Thrower with wind-up + landing marker + stone cap, wall with 3 looks, small HUD (wall HP, coins, enemies left), "Wall Held!" / "Wall Fell!" + click to restart.
2. **Effects pass:** all effects in section 8 (no sound yet).
3. **Progression + shop:** 3 walls, coins, retake bonus, choice screen, fall back, shop.
4. **Slinger + Catapult** and the real wave rows.
5. **Menus:** start menu, story with Skip, win/lose screens.
6. **Sound + music**, `assets/README.md` replace guide.
7. **Balance + web export** (Thread Support OFF, `build/web/index.html`, test with `python -m http.server`).

---

## 10. Tech rules

- Renderer **Compatibility**. GDScript only. No file saves, no networking.
- `GameState` is the only autoload (coins, upgrade levels, current wall, per-wall HP, signals).
- Use signals between nodes (`wall_fallen`, `enemy_died`, `wave_cleared`, `coins_changed`).
- Collision layers: 1 `shield`, 2 `hostile_stone`, 3 `returned_stone`, 4 `enemy`, 5 `wall`, 6 `world_edge`.
