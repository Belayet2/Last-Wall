# Last Wall (Godot project)

## Overview
2D jam game for theme "Bounce Back". A hero with a fixed flat shield moves left/right above a castle wall and bounces rocks thrown by ships back at them. **The full design spec and build steps are in `../CLAUDE.md`** — follow it. This file tracks the current state of the code.

Current state: **Step 1 done** (core loop, Wall 1 only, win/lose + click to restart).

## Tech Stack
- Godot 4.7.2 (`D:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` for CLI)
- GDScript only, Compatibility renderer, 1280×720, stretch `canvas_items` / `keep`
- Web export preset "Web" (threads off) → `build/web/index.html`
- Placeholder art generated with Python + Pillow (`tools/make_assets.py`, ignored by Godot via `.gdignore`)

## Project Structure
```
project.godot  export_presets.cfg
scenes/  game.tscn hero.tscn shield.tscn wall.tscn projectile.tscn
         enemies/thrower.tscn   ui/hud.tscn
scripts/ game.gd hero.gd shield.gd wall.gd projectile.gd enemy_base.gd wave_manager.gd hud.gd fx.gd
         autoload/game_state.gd   (only autoload: coins, current_wall, upgrade values)
         data/game_config.gd level_data.gd enemy_data.gd   (all tuning numbers)
assets/  sprites/*.png  README.md (how to swap art)  CREDITS.txt  audio/ fonts/
tools/   make_assets.py
```

## Conventions
- All tuning numbers live in `scripts/data/*.gd` (`class_name` + `const`). No magic numbers in logic.
- Sprites are scaled at runtime to a gameplay size with `Fx.fit_sprite`, so any PNG resolution can be dropped in.
- Projectiles are `Area2D` moved manually; the projectile handles its own collisions in `_on_area_entered` and calls `shield.handle_projectile`, `wall.take_damage`, `enemy.take_hit`.
- Groups: `shield`, `wall`, `enemy` (dead enemies leave the group).
- Collision layers (bits): shield 1, hostile 2, returned 4, enemy 8, wall 16, obstacle 32, world_edge 64. Side edges are handled in code (`projectile.gd`), not with bodies.
- Nodes talk with signals (`threw`, `died`, `wave_cleared`, `hp_changed`, `wall_fallen`, `coins_changed`, `restart_requested`).
- End of wave: `get_tree().paused = true`; HUD is `process_mode = Always` and emits `restart_requested` on click.

## Setup & Commands
- Open: Godot → Import → `last_wall/project.godot`, press F5.
- CLI check: `godot --headless --path . --quit-after 600` (no output = no errors).
- Rebuild placeholder art: `python tools/make_assets.py`
- Web export (needs Web export templates installed): `godot --headless --path . --export-release "Web" build/web/index.html`, then `python -m http.server` in `build/web`.

## Notes
- Shield bounce = `velocity.bounce(normal tilted by offset*40°)`, then clamped to within `RETURN_MAX_ANGLE_DEG` (60°) of straight up so edge hits never go flat/downward.
- Web export templates for 4.7.2 are not installed yet (only Windows ones) — install via Editor → Manage Export Templates.
- `../minimal/` is an older all-in-code prototype; this folder is the real project.
