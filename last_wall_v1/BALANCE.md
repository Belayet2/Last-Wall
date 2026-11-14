# How to balance Last Wall

Every number that makes the game easier or harder is in **5 files** in `scripts/data/`. You never need to touch the game code to balance.

| File | What it controls |
|---|---|
| `level_data.gd` | The 5 walls: which enemies, how strong each wall's last layer is, how many balls fly at once |
| `enemy_data.gd` | Each enemy: HP, how often it shoots, ball speed, damage, coins; the boss |
| `brick_data.gd` | The bricks: HP and price of each, the wall grid, starting bricks |
| `shop_data.gd` | Coins: starting coins, the bonus for taking a wall back, the shield upgrades and their prices |
| `game_data.gd` | How the hero and shield feel: bounce angle, how fast bounced balls fly back |

## How to change a number

1. Open the file in Godot (FileSystem dock → `scripts/data/` → double-click) or in any text editor.
2. Change **only the number**. Keep the rest of the line as it is: the quotes, the colon, the comma at the end, `.0` on numbers that have it (`150.0` stays a decimal, `8` stays a whole number).
3. Save (Ctrl+S) and press **F5** to play.
4. Change **one or two numbers at a time**, then test. If you change ten things at once you won't know which one helped.
5. If Godot shows a red error after your change, you broke the format (usually a missing comma or quote). Press Ctrl+Z.

## Test fast

- **Start at any wall:** in `level_data.gd` set `START_WALL := 3` to start the game on Wall 3. Give yourself coins with `START_COINS` in `shop_data.gd` and bricks with `START_BRICKS` in `brick_data.gd`, e.g. `const START_BRICKS := {"stone": 10, "clay": 5}`. **Put them back (1, 0, {}) before you publish.**
- **Skip the story:** the "Skip story" button.
- **Let a bot play it for you.** It plays the whole game in about a minute without a window and prints how long each wall took, how many bricks broke and whether it won. Run it in a terminal from the `last_wall_v1` folder (use your Godot **console** exe):

```
"D:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --fixed-fps 60 --script res://tools/balance_bot.gd -- casual
```

Players: `good`, `sloppy`, `casual` (a new player; the most useful), `idle` (never moves). Add a number for a different random run: `-- casual 7`. Run each one 2-3 times; one run can be lucky.

**Today's results:** good wins in about 3 min, sloppy about 4.5 min, casual 6-7 min, all without falling back. That is **easy**. A good target for a jam game: casual wins in 6-10 min and falls back 0-2 times.

The bot is a little better than a person at reading where a ball will land, so a real new player will find the game harder than `casual`. **Always play it yourself too**, and if you can, watch a friend play without helping.

## The big knobs (start here)

| You want... | Change | In |
|---|---|---|
| **Easier overall** | Lower `"wall_damage"` of the enemies (e.g. cannon 8 → 6) | `enemy_data.gd` |
| | Raise `"foundation_hp"` of the walls (last layer HP) | `level_data.gd` |
| | Fewer balls in the air: lower `"max_stones"` (2 → 1 on early walls) | `level_data.gd` |
| | Slower balls: lower `"stone_speed"` | `enemy_data.gd` |
| **Harder overall** | The opposite of the above, or longer `"enemies"` lists | `level_data.gd` |
| **Shorter waves** | Lower enemy `"hp"`, or raise `"start"` of Stone Power (bounced balls hit harder) | `enemy_data.gd`, `shop_data.gd` |
| **Building matters more** | Raise `"wall_damage"` and make bricks cheaper (`"cost"`) | `enemy_data.gd`, `brick_data.gd` |
| **More / fewer coins** | `"coins"` per enemy, `RETAKE_BONUS_PER_WALL` | `enemy_data.gd`, `shop_data.gd` |
| **Can actually lose the Last Wall** | Lower `"prebuilt_hp"` on Wall 1 (now 20; an idle player cannot break it) | `level_data.gd` |
| **Boss shorter / easier** | Lower `"hp"` (60) or `"volley"` in its `"phases"` | `enemy_data.gd` → `BOSS` |

## Every number, file by file

### `level_data.gd`: the walls

Each wall is one `{ ... }` block, Wall 1 first.

| Key | Now (wall 1 → 5) | What it does | Easier = |
|---|---|---|---|
| `"foundation_hp"` | 40, 34, 30, 26, 24 | HP of each brick of the last layer. **One of them breaks = the wall falls** | higher |
| `"prebuilt_hp"` | 20 (Wall 1 only) | HP of the Last Wall's upper 3 rows (it starts whole) | higher |
| `"max_stones"` | 2, 2, 3, 3, 4 | How many balls can be flying at the same time. **The strongest difficulty knob** | lower |
| `"enemies"` | e.g. `["cannon", "cannon", "cannon"]` | Who is on this wall, left to right. Use `"cannon"`, `"slinger"`, `"catapult"` | fewer / weaker |
| `"tip"` | text | Shown when the wave starts | |
| `START_WALL` | 1 | Testing only (see above) | |

### `enemy_data.gd`: the enemies

Each enemy type is a block in `TYPES`:

| Key | Cannon | Slinger | Catapult | What it does | Easier = |
|---|---|---|---|---|---|
| `"hp"` | 2 | 1 | 4 | Bounced balls needed to destroy it (1 damage each, catapult boulders 2) | lower |
| `"throw_interval"` | 3.0 | 2.2 | 5.0 | Seconds between shots | higher |
| `"stone_speed"` | 150 | 200 | 110 | How fast its ball flies (pixels per second) | lower |
| `"wall_damage"` | 8 | 5 | 20 | Damage to a brick when you miss | lower |
| `"coins"` | 5 | 4 | 15 | Coins for destroying it | higher |
| `"windup_time"` | 0.7 | 0.6 | 1.1 | Warning time: it aims / winds up this long before shooting | higher |
| `"aim_spread"` | 330 | 400 | 240 | It shoots at the wall up to this far left/right of where it stands | (smaller = easier to guard, but holes form faster there) |
| `"return_damage"` | 1 | 1 | 2 | Damage its ball does when you bounce it back | higher |
| `"stone_size"` | 22 | 15 | 32 | Size of its ball (looks only) | |

Shared numbers at the top: `INTERVAL_JITTER` (random ±15% on each interval), `FIRST_THROW_DELAY_MIN` (the first shot comes after at least 1.5 s), `HITBOX_SCALE` (1.3 = enemies are 30% easier to hit than they look; higher = easier).

**The boss** (`BOSS`, Wall 5): `"hp"` 60, `"ball_speed"` 175, `"wall_damage"` 12, `"windup"` 1.0 s warning (it glows), `"volley_gap"` 0.7 s between the balls of one volley. `"phases"`: it gets angrier below 66% and 33% HP; each phase has `"interval"` (seconds between volleys), `"volley"` (balls per volley: 2, 3, 4) and `"sail_speed"`. `BOSS_SWEEP_STEP` = how far apart the balls of a "sweep" land (bigger = you must run further).

### `brick_data.gd`: the bricks

| Brick | `"hp"` | `"cost"` | Takes this many cannon balls |
|---|---|---|---|
| Mud | 8 | 2 | 1 |
| Clay | 16 | 4 | 2 |
| Stone | 30 | 7 | 4 |
| Marble | 48 | 11 | 6 |

- Keep the price per HP roughly even (about 0.25 coins per HP), or one brick becomes the only good choice. Strong bricks are a little cheaper per HP because they use fewer places on the wall.
- `START_BRICKS` = bricks you have at the start (now none: you build from Wall 2).
- `ROWS` = 4 (last layer + 3 rows you build). More rows = you can build higher = easier.
- `COLUMNS`, `BRICK_W`, `BRICK_H`: the grid. Leave them unless you also redraw the bricks.

### `shop_data.gd`: coins and upgrades

| Key | Now | What it does |
|---|---|---|
| `START_COINS` | 0 | Coins at the start |
| `RETAKE_BONUS_PER_WALL` | 40 | Coins for clearing a wall = this × wall number (40, 80, 120, 160...). Paid again after falling back, so a struggling player can catch up |
| `BRICK_BUY_MANY` | 5 | The shop's second buy button |

Upgrades (`UPGRADES`): `"start"` = value with no upgrade, `"per_level"` = added per level, `"costs"` = price of each level (the number of prices = the number of levels).

| Upgrade | Start | Per level | Prices |
|---|---|---|---|
| Shield Aura (bounce zone width, px) | 140 | +25 | 20, 40, 60 |
| Move Speed (px per second) | 360 | +40 | 15, 30, 50 |
| Aim Assist (how much bounced balls curve to an enemy, 0-1) | 0.6 | +0.1 | 25, 45, 70 |
| Stone Power (extra damage of bounced balls) | 0 | +1 | 40, 80 |

A whole run earns about 320 coins, so a player can't buy everything: they choose between bricks and upgrades. If you make upgrades much cheaper, bricks stop mattering.

### `game_data.gd`: how it feels

| Key | Now | What it does |
|---|---|---|
| `RETURN_SPEED_MULT` | 1.6 | Bounced balls fly back this much faster than they came (higher = waves end sooner) |
| `MAX_BOUNCE_ANGLE_DEG` | 45 | Hitting the edge of the aura sends the ball off at up to this angle |
| `AURA_HEIGHT` | 42 | How high the golden bounce arc rises over the shield |
| `STONE_LIFETIME` | 8 | A ball disappears after this many seconds |
| `INTRO_HOLD` | 1.8 | How long "WALL 1" stays on screen |

## A good way to work

1. Decide what you want to change, in one sentence ("Wall 3 is too hard for new players").
2. Play it, or run `casual` 3 times, and write down the numbers (time, falls, bricks broken).
3. Change one number by about 20% (e.g. `wall_damage` 20 → 16).
4. Test again the same way and compare.
5. Keep it or undo it. Commit in git when you are happy, so you can always go back.
