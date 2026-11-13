# Last Wall (web)

## Overview
Web/TypeScript version of the jam game described in `../CLAUDE.md` (theme "Bounce Back"). You defend the castle wall with a flat shield and bounce the enemies' rocks back at their ships. **That parent CLAUDE.md is the design spec**: mechanics, numbers, and the step-by-step build plan (section 10). It describes a Godot project. This folder builds the same game in TypeScript, and the Godot-specific rules (GDScript, Compatibility renderer, export presets) are replaced by the stack below.

**Current progress: Step 1 (core loop) is done.** That covers Wall 1, the hero, the shield, the wall, 3 throwers, projectiles, the HUD, the win/lose banner, and click to restart.

## Tech Stack
- **Phaser 3.90** (2D game framework), rendered with WebGL and a Canvas fallback
- **TypeScript** (strict) + **Vite** for the dev server and build
- **pnpm** as the package manager
- No physics engine. Projectiles move by hand with a velocity vector, and collisions are circle-vs-rect checks (`src/utils/math.ts`).

## Project Structure
```
last_wall_web/
  index.html
  vite.config.ts           base './' so dist/ works on itch.io
  public/assets/
    sprites/*.svg          all art (original SVGs, easy to replace)
    CREDITS.txt
  src/
    main.ts                Phaser game config
    config.ts              screen/field layout, depths, colors, font
    assets.ts              ASSET MANIFEST: key -> file + draw size
    input.ts               input map (move_left, move_right, pause)
    data/                  ALL balance numbers
      heroData.ts          hero speed, shield size/tilt/bounce rate/aim
      enemyData.ts         enemy types (only thrower so far)
      levelData.ts         one row per wall (only wall 1 so far)
      projectileData.ts    radius, lifetime
      wallData.ts          damaged/broken thresholds
    state/gameState.ts     global run state (coins, current wall, hero stats), event emitter
    objects/               Hero, Shield, Wall, Enemy, Projectile
    scenes/BootScene.ts    loads the manifest
    scenes/GameScene.ts    play field, throwing, collisions, round flow
    ui/Hud.ts              side panels, banners, pause overlay
    ui/fx.ts               puff, ring, floating text
    ui/style.ts            text style helper
```

## Conventions
- **Balance numbers go in `src/data/`.** Layout goes in `src/config.ts`. Don't put magic numbers in the logic.
- **Art is swapped only in `src/assets.ts`.** Every sprite is drawn at the manifest's `width`/`height`, so any replacement image fits. Hitboxes come from `src/data/`, not from sprite sizes.
- `GameState` is the only global. Objects talk through events (`coins_changed`, `hp_changed`, `wall_fallen`).
- All enemy types share `objects/Enemy.ts` and differ only by their `ENEMY_DATA` entry.
- `scene.restart()` reuses the scene instance, so reset per-round fields in `create()`, not in field initializers.
- Listeners on `GameState` must be removed on scene `SHUTDOWN` (see `Hud`).

## Setup & Commands
```
pnpm install
pnpm dev          # http://localhost:5173
pnpm typecheck
pnpm build        # outputs dist/ (zip the contents for itch.io)
pnpm preview      # serve the built dist/
```

## Replacing assets
1. Put the new file in `public/assets/sprites/` (SVG/PNG/JPG/WEBP).
2. Change that key's `file` in `src/assets.ts`. Adjust `width`/`height` if the draw size should change.
3. For pixel art, add `pixelArt: true`.
A wrong path logs `[assets] Could not load ...` in the console and shows Phaser's missing-texture box.

## Notes
- **Shield bounce:** `SHIELD_DATA.bounceMode = 'paddle'` (default) sends the shot along the tilted normal, so a center hit goes straight up and an edge hit goes out at 40°, as the spec's examples describe. A literal `velocity.bounce(normal)` doubles the angle (up to 80°), so it is kept as the `'reflect'` option.
- Audio is off (`audio.noAudio`) until step 6 adds the "Click to Start" screen.
- No wave manager yet. `GameScene` counts enemies itself. Step 2 adds the 5-wall state machine and the shop.
- Dev builds expose `window.game` for console debugging.
