import Phaser from 'phaser';

/**
 * ASSET MANIFEST — the one place to swap art.
 *
 * To replace a sprite: drop your file into public/assets/sprites/ and change `file` below.
 * SVG, PNG, JPG and WEBP all work. Whatever you load is scaled to `width` x `height`,
 * so a new image always fits the game without touching any gameplay code.
 * Set `pixelArt: true` for pixel-art PNGs to keep them crisp.
 *
 * Hitboxes are NOT taken from these sizes; they live in src/data/.
 */
export interface AssetDef {
  /** Path inside public/assets/. */
  file: string;
  /** Size the sprite is drawn at in the game. */
  width: number;
  height: number;
  /** true = nearest-neighbour scaling (for pixel art). */
  pixelArt?: boolean;
}

export const ASSETS = {
  bg_field: { file: 'sprites/bg_field.svg', width: 560, height: 720 },
  bg_side: { file: 'sprites/bg_side.svg', width: 360, height: 720 },
  hero: { file: 'sprites/hero.svg', width: 44, height: 60 },
  shield: { file: 'sprites/shield.svg', width: 120, height: 24 },
  wall_full: { file: 'sprites/wall_full.svg', width: 560, height: 70 },
  wall_cracked: { file: 'sprites/wall_cracked.svg', width: 560, height: 70 },
  wall_broken: { file: 'sprites/wall_broken.svg', width: 560, height: 70 },
  enemy_thrower: { file: 'sprites/enemy_thrower.svg', width: 84, height: 76 },
  projectile_hostile: { file: 'sprites/projectile_hostile.svg', width: 20, height: 20 },
  projectile_returned: { file: 'sprites/projectile_returned.svg', width: 22, height: 22 },
  coin: { file: 'sprites/coin.svg', width: 22, height: 22 },
} satisfies Record<string, AssetDef>;

export type AssetKey = keyof typeof ASSETS;

/** SVGs are rasterised at this multiple of their draw size so they stay sharp when the window is scaled up. */
const SVG_RASTER_SCALE = 2;

function entries(): [AssetKey, AssetDef][] {
  return Object.entries(ASSETS) as [AssetKey, AssetDef][];
}

export function preloadAssets(scene: Phaser.Scene): void {
  scene.load.setPath('assets/');
  for (const [key, def] of entries()) {
    if (def.file.toLowerCase().endsWith('.svg')) {
      scene.load.svg(key, def.file, {
        width: def.width * SVG_RASTER_SCALE,
        height: def.height * SVG_RASTER_SCALE,
      });
    } else {
      scene.load.image(key, def.file);
    }
  }
}

export function applyTextureFilters(scene: Phaser.Scene): void {
  for (const [key, def] of entries()) {
    if (def.pixelArt) scene.textures.get(key).setFilter(Phaser.Textures.FilterMode.NEAREST);
  }
}

/** Add an image at its manifest size. */
export function addSprite(scene: Phaser.Scene, x: number, y: number, key: AssetKey): Phaser.GameObjects.Image {
  const def: AssetDef = ASSETS[key];
  return scene.add.image(x, y, key).setDisplaySize(def.width, def.height);
}

/** Swap an image's texture and keep it at the new asset's manifest size. */
export function setSpriteTexture(image: Phaser.GameObjects.Image, key: AssetKey): void {
  const def: AssetDef = ASSETS[key];
  image.setTexture(key).setDisplaySize(def.width, def.height);
}
