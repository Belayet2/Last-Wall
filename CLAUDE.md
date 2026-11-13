# CLAUDE.md — "Last Wall" (working title)

Hackathon game. Theme: **"Bounce Back"**. Hard deadline: **5 hours total**. Everything below is written so that you (Claude Code) can build this game step by step without asking many questions.

---

## 0. How to work (read this first)

1. **Build ONE step at a time.** The steps are listed in section 10. Do only the step the user asks for. Do not start the next step on your own.
2. **After every step, the game must run with no errors** (`godot --headless --quit` or just open the project). Then tell the user, in 3–5 short lines, what to test.
3. **No preamble, no long explanations.** Short summary at the end. If you change a rule from this file, say why in one line.
4. **Keep it simple.** The simplest code that works wins. No plugins, no addons, no fancy patterns. This is a 5-hour jam game.
5. **Placeholders first.** If an art/sound asset is missing, use a colored `ColorRect`, `Polygon2D`, or a Godot built-in icon. Never block on assets.
6. **Make numbers easy to tune.** All balance numbers (HP, speeds, costs, timers) live in `scripts/data/` or as `@export` variables. Never bury magic numbers in logic.
7. **Don't break the web export.** Follow section 3 at all times.
8. **Commit after every finished step** (`git add -A && git commit -m "step N: ..."`) if git is set up.

---

## 1. Game summary

A 2D defense game. You are a soldier with a powerful shield. Enemy ships stand off the coast and throw projectiles at your castle wall. You **bounce the projectiles back at the enemies** with your shield. If you miss, the projectile hits the wall behind you and damages it. If the wall breaks, you fall back to the previous wall.

- **Setting:** An island kingdom. The war was won, but most soldiers died. More enemies are coming by sea. All outer walls have fallen. The king calls the hero.
- **Win:** Clear the wave on **Wall 5** (the boss wall).
- **Lose:** Wall 1 (the innermost wall) breaks.
- **Theme link (Bounce Back):** (a) the shield bounces projectiles back, (b) when a wall falls, the hero bounces back to the previous wall and fights again, and (c) retaking a wall heals it to 100%.

### Wall structure
There are **5 walls**. Wall 1 is the innermost (strongest). Wall 5 is the outermost (weakest). **The further out the hero goes, the weaker the wall and the stronger the enemies.**

---

## 2. Screen layout (important — keep this exactly)

Portrait-style play field inside a landscape window (target window: **1280×720**, stretch mode `canvas_items`, aspect `keep`).

```
 ┌──────────────────────────────┐
 │   ENEMIES (top, don't move)  │  <- stand in a row at the top, only throw
 │                              │
 │     obstacles (mid field)    │  <- later step
 │                              │
 │        ◄── HERO ──►          │  <- moves LEFT/RIGHT only, on a fixed Y
 │   ████████ WALL ████████     │  <- bottom, full width, BEHIND the hero
 └──────────────────────────────┘
```

- Projectiles fly **downward** toward the wall.
- The hero is **just above the wall**. The hero **cannot move up/down**.
- The hero carries a **fixed shield** just above him. It moves left/right with the hero and **never rotates** (section 4).
- Left and right edges of the play field are solid: returned projectiles **bounce off them**.

---

## 3. Tech rules (web export safe)

- **Engine:** Godot **4.7.2**. Its at D:\Godot\Godot_v4.7.2-stable_win64.exe.
- **Language:** **GDScript only.** C# does NOT export to web in Godot 4.
- **Renderer:** **Compatibility** (the only one that works for web).
- **Web export:** Thread Support **OFF**. Export to `build/web/index.html`.
- **No external networking, no file system saves** (use in-memory state; `ConfigFile` only if really needed).
- **Audio:** Browsers block audio until the first click. The title screen must have a **"Click to Start"** button. Start music/sfx only after that click.
- **Input:** Keyboard only for gameplay (the mouse is used only to click UI buttons). Create these Input Map actions: `move_left` (A, Left arrow), `move_right` (D, Right arrow), `pause` (Esc). **There is no shield aiming and no shield rotation.** The only way to control the shield is by moving the hero.
- **Keep the exported build small.** Compress images, use `.ogg` for audio, avoid huge files.
- **Test the web export after Step 1** and again at the end. Serve the build folder locally with `python -m http.server` and open `localhost:8000` (opening `index.html` directly will not work).

---

## 4. Core mechanics (the rules)

### 4.1 Hero
- Moves left/right with A/D (and arrows). Fixed Y. Stays inside the play field.
- Base move speed: **220 px/s** (upgradeable).
- **The hero has no health.** Only the wall has health. (This keeps the game simple.)
- Projectiles pass through the hero's body. Only the shield and the wall matter.

### 4.2 Shield
- The shield is a **flat horizontal paddle** fixed about **40 px above the hero**, about **110 px wide** (an `Area2D` with a `CollisionShape2D`). It is a child of the hero, so it moves with him.
- **The shield does NOT move on its own and does NOT rotate. There is no mouse aiming.** The player controls it only by moving the hero left/right with A/D.
- **Skill comes from WHERE on the shield the projectile lands:** the bounce direction depends on the hit position along the paddle. Compute `offset = clamp((hit_x - shield_center_x) / (shield_width / 2), -1, 1)`. The bounce normal is straight up, tilted by `offset * 40°` (center hit = straight up, edge hit = sent sideways at up to 40°). This lets the player aim by positioning the hero.
- **Bounce chance (`bounce_rate`):** when a hostile projectile touches the shield, roll `randf() < bounce_rate`.
  - **Success → BOUNCE:** the projectile is reflected using the tilted normal described above (`velocity.bounce(normal)`), its speed goes up ×1.25, it becomes a **returned** projectile (it can now hurt enemies, and can no longer hurt the wall). Play a bright flash on the shield.
  - **Fail → FIZZLE:** the projectile is blocked but not returned. It disappears with a small gray puff. **It does NOT damage the wall.** Show a **gray flash** on the shield so the player understands it was bad luck, not a bug.
- Start values: `bounce_rate = 0.40`.
- **Aim accuracy (`aim_accuracy`, 0.0–1.0):** after a successful bounce, turn the new direction toward the nearest living enemy by `aim_accuracy` (use `lerp_angle`). At 0.0 it's pure physics reflection. At 0.6 it's strongly nudged. Start value: `0.0`.
- The shield must not be able to hit the same projectile twice in one frame (use a flag or a short per-projectile cooldown).

### 4.3 Projectiles
Two states: **hostile** and **returned**.

| | Hostile | Returned |
|---|---|---|
| Thrown by | enemy | created when the shield bounces a hostile one |
| Hits the wall | damages the wall, then disappears | passes through / ignores the wall |
| Hits the shield | roll for bounce (4.2) | ignores the shield |
| Hits an enemy | ignores | damages the enemy, then disappears |
| Hits an obstacle | bounces off it | bounces off it |
| Hits the side edges | bounces off | bounces off |

- Use `Area2D` or `CharacterBody2D` and move them **manually** with a velocity vector. Do NOT use `RigidBody2D` for projectiles (too unpredictable). Reflect with `Vector2.bounce(normal)`.
- Remove any projectile that leaves the screen, or after **8 seconds**.
- **Not straight (added in Step 3):** hostile projectiles get a small random launch angle and a gentle sideways curve (a small sine wobble added to the direction). Returned projectiles fly straight, so the player can plan ricochets.

### 4.4 Enemies
- Enemies **stand still** in a row at the top. They **never move forward**. They only throw.
- Each enemy has `max_hp`, `throw_interval`, `projectile_speed`, `damage`, and `coin_reward`, all read from a data file.
- Throw logic: every `throw_interval` seconds (with a small random offset so they don't all throw together), spawn a hostile projectile aimed at a **random point along the wall**, plus a small random angle error.
- When an enemy dies: play a pop effect, give coins, and tell the wave manager.

**Enemy types:**

| Type | Look/behavior | HP | Throw interval | Projectile speed | Wall damage | Coins |
|---|---|---|---|---|---|---|
| **Thrower** | normal, steady | 3 | 2.8 s | 180 | 10 | 5 |
| **Fast Thrower** | small, quick, weak shots | 2 | 1.6 s | 260 | 5 | 8 |
| **Heavy Thrower** | big, slow, hits wall very hard | 5 | 4.0 s | 120 | 30 | 12 |
| **Boss** (Wall 5 only) | huge, throws a mix of all three shot types, moves slowly left/right at the top | 40 | 1.4 s | mixed | mixed | 100 |

*(These are starting numbers. They are meant to be tuned. Keep them in `scripts/data/enemy_data.gd`.)*

Returned projectile damage to enemies: **1 HP per hit** (Heavy shots returned: **3 HP**).

### 4.5 Wall
- Sits at the bottom, full width, **behind** the hero.
- Has `max_hp`, `hp`, and a `state`: `HELD`, `DAMAGED`, or `FALLEN`.
- Show an HP bar and change the look by HP (full → cracked → broken). Placeholders are fine: change the color.
- When `hp <= 0`: emit `wall_fallen`.

---

## 5. Wall progression (the "Bounce Back" loop)

One simple state machine drives the whole game:

```
current_wall = 1
loop:
    play the wave of current_wall
    if wave cleared (all enemies dead):
        wall.hp = 100% of max   <- "retaking" heals it fully
        give retake bonus coins
        if current_wall == 5: WIN
        else: open SHOP, then current_wall += 1
              (the next wall is FALLEN; see repair rules below)
    if wall hp reaches 0:
        wall becomes FALLEN
        if current_wall == 1: GAME OVER
        else: current_wall -= 1, open SHOP, replay that wall's wave
              (the hero "bounces back" and defends the previous wall)
```

### Repair rules (shop)
- When the hero moves to a fallen wall, that wall starts with **20 HP for free** (so the player is never stuck with 0 coins).
- In the shop, coins can buy **Repair**: more starting HP for the wall the hero is about to defend.
- Clearing the wave heals the wall to **100%** automatically.
- If the hero retreats to a previous wall, that wall keeps whatever HP it currently has (it was healed to 100% when retaken, so it's usually full).

---

## 6. Coins and shop

**Coins come from:** killing enemies (see enemy table) and retaking a wall (bonus: `30 × wall_number`).

**Shop** opens between waves. Simple full-screen panel, 5 buttons, shows coins, and a **"Continue"** button. The game is paused while the shop is open.

| Upgrade | Start | Per level | Max level | Cost (per level) |
|---|---|---|---|---|
| **Bounce Rate** | 40% | +10% | 6 (→ 100%) | 20, 35, 50, 70, 90, 120 |
| **Move Speed** | 220 | +25 | 5 | 15, 25, 40, 60, 80 |
| **Aim Accuracy** | 0.0 | +0.15 | 4 (→ 0.6) | 30, 50, 80, 120 |
| **Repair Wall** | — | +10 HP to the next wall | unlimited | 2 coins per HP |
| **Reinforce Walls** | — | +15 max HP to all walls | 4 | 40, 70, 100, 140 |

Upgrades persist for the whole run. Keep all costs in `scripts/data/shop_data.gd`.

---

## 7. Level data (all 5 walls)

Put this in `scripts/data/level_data.gd` as a constant array so that making a wall is just filling a row.

| Wall | Wall max HP | Enemies in the wave | Types |
|---|---|---|---|
| 1 | 150 | 3 | Thrower |
| 2 | 120 | 4 | Thrower, Fast Thrower |
| 3 | 100 | 5 | Thrower, Fast, Heavy |
| 4 | 80 | 6 | all three |
| 5 | 60 | Boss + 4 | all three + Boss |

Obstacles per wall (added in Step 3): Wall 1: 0, Wall 2: 1, Wall 3: 2, Wall 4: 3, Wall 5: 3.

---

## 8. Story (keep it tiny)

Show **3 text screens** at the start (static image or color + text, click to continue):

1. *"The war is over. We won. But most of our soldiers did not come home."* (the commander speaks to the king)
2. *"My king, ships are coming from the sea. More of them than before."* (a messenger runs in)
3. *"Every wall has fallen. There is no army left. ...Call the hero."*

Win screen: *"The sea is quiet. The kingdom is saved."* Lose screen: *"The last wall has fallen."* with a **Try Again** button.

---

## 9. Project structure

```
res://
  project.godot
  CLAUDE.md
  scenes/
    main.tscn            (title screen -> story -> game)
    game.tscn            (the play field)
    hero.tscn
    shield.tscn
    wall.tscn
    projectile.tscn
    obstacle.tscn
    enemies/
      thrower.tscn  fast_thrower.tscn  heavy_thrower.tscn  boss.tscn
    ui/
      hud.tscn  shop.tscn  story.tscn  end_screen.tscn
  scripts/
    hero.gd  shield.gd  wall.gd  projectile.gd  enemy_base.gd
    wave_manager.gd  game.gd
    autoload/
      game_state.gd      (coins, upgrades, current_wall, wall HP list, signals)
    data/
      level_data.gd  enemy_data.gd  shop_data.gd
  assets/
    sprites/  audio/  fonts/  CREDITS.txt
```

- **`GameState` is the only autoload.** It holds coins, upgrade levels, `current_wall`, and per-wall HP. Everything else talks to it through signals.
- Enemies share one `enemy_base.gd` and differ only by data + sprite.
- Use **signals** between nodes (e.g. `wall_fallen`, `enemy_died`, `wave_cleared`, `coins_changed`). Avoid long `get_node` chains.

### Collision layers (set names in Project Settings)
1 `hero_shield`, 2 `hostile_projectile`, 3 `returned_projectile`, 4 `enemy`, 5 `wall`, 6 `obstacle`, 7 `world_edge`.

---

## 10. Build steps (do one at a time, when asked)

**Step 1 — Core loop (FIRST RUN).** Build only this:
- Project setup (Compatibility renderer, 1280×720, input actions, folder structure, `GameState` autoload with just the basics).
- **Hero** with A/D movement (fixed Y, clamped to the field).
- **Shield**: fixed flat paddle above the hero (no rotation, no mouse), with the hit-position bounce angle, bounce roll, fizzle, and aim accuracy (default 0).
- **Wall** at the bottom with HP, HP bar, and the `wall_fallen` signal.
- **Thrower** enemy (3 of them in a row at the top) that throws hostile projectiles at the wall.
- **Projectile** with hostile/returned states, side-edge bounces, and enemy damage.
- **Wall 1 only.** When all enemies die: show "Wall Held!". When the wall breaks: show "Wall Fell!" and restart the scene on a click.
- A tiny HUD: wall HP bar, coin counter (coins count up, no shop yet), enemies left.
- Placeholder graphics only (colored shapes).
- **Done when:** the user can play wall 1, bounce projectiles, kill all 3 throwers, win, or lose.

**Step 2 — Progression + shop.** Coins on kills, the 5-wall state machine (advance, retreat, repair), the shop with the 5 upgrades, and the game over screen. Use temporary copies of Wall 1's wave for the other walls.

**Step 3 — Obstacles + curved projectiles.** Angled obstacle blocks in the mid field that reflect projectiles. Hostile projectiles get the random angle and sine curve.

**Step 4 — Fast Thrower + Heavy Thrower + all 5 wall rows from `level_data.gd`.**

**Step 5 — Boss.**

**Step 6 — Title screen ("Click to Start"), story screens, win/lose screens.**

**Step 7 — Juice.** Screen shake on wall hit, particles on bounce and enemy death, coin pop, simple sfx (bounce, hit, wall damage, coin, button), 1 music loop, hit-stop (30 ms) on a successful bounce that kills an enemy. Optional: **ricochet bonus**: +2 coins if a returned projectile bounces off an obstacle before killing an enemy.

**Step 8 — Balance + web export + itch.io.** Play all 5 walls, tune numbers, test the web build, upload the zip to itch.io (HTML5, "play in browser").

---

## 11. Assets

- Prefer **one** art pack so the game looks consistent. CC0 or clearly free-to-use only.
- Good sources: Kenney.nl, itch.io free assets, OpenGameArt.org (check the license on each).
- Put the files in `assets/`, and list the source + license of everything used in `assets/CREDITS.txt`.
- Sprites: use `texture_filter = Nearest` for pixel art.
- Audio: `.ogg`, normalized, short. Keep music under about 1.5 MB.

---

## 12. Definition of done (for every step)

- [ ] The project opens and runs with **zero errors or warnings** in the Output panel.
- [ ] The new feature works as described in this file.
- [ ] Nothing from an earlier step is broken.
- [ ] The balance numbers are in data files, not hard-coded.
- [ ] A short note to the user: what was built, what to test, and (if any) what you assumed.