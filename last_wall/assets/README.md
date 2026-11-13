# Swapping the art

Every sprite is a PNG in `assets/sprites/`. **To use your own art, overwrite the PNG with the same file name.**
Any resolution works: the game scales each sprite to its gameplay size (`Fx.fit_sprite`), so hitboxes never change.
Use transparent PNGs. Pixel art stays crisp (texture filter is Nearest project-wide).

| File | Used for | Shown at (px) | Size set in |
|---|---|---|---|
| `hero.png` | the hero, seen from above | 48 × 48 | `GameConfig.HERO_SIZE` |
| `shield.png` | the flat shield paddle | 110 × 16 | `GameConfig.SHIELD_WIDTH / SHIELD_THICKNESS` |
| `thrower.png` | Thrower enemy (boat) | 56 × 56 | `EnemyData.TYPES.thrower.size` |
| `projectile_hostile.png` | rock flying at the wall | 14 × 14 | `GameConfig.PROJECTILE_RADIUS` |
| `projectile_returned.png` | rock after your shield bounced it | 14 × 14 | `GameConfig.PROJECTILE_RADIUS` |
| `wall_full.png` / `wall_cracked.png` / `wall_broken.png` | the wall by HP (100–66% / 66–33% / <33%) | 560 × 80 | `GameConfig.WALL_HEIGHT`, field width |
| `background.png` | the play field (sea at top, grass) | 560 × 720 | field size in `GameConfig` |
| `puff.png` | white soft circle, tinted for hit/bounce/fizzle puffs | varies | `scripts/fx.gd` |
| `icon.png` | window / web icon | 64 × 64 | `project.godot` |

Best results: keep the same aspect ratio as the table (e.g. wall 140×20 or 560×80).

Other ways to change art:
- In the Godot editor, open a scene (`scenes/hero.tscn`, `scenes/enemies/thrower.tscn`, ...) and drag a new texture onto its `Sprite2D`.
- Wall and projectile textures are also `@export` fields on the root node of `scenes/wall.tscn` and `scenes/projectile.tscn`.

The placeholder PNGs were made by `tools/make_assets.py` (`python tools/make_assets.py` rebuilds them, overwriting yours).
Add the source + license of any art you bring in to `CREDITS.txt`.
