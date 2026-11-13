import Phaser from 'phaser';
import { applyTextureFilters, preloadAssets } from '../assets';
import { COLORS, GAME_HEIGHT, GAME_WIDTH } from '../config';
import { textStyle } from '../ui/style';

/** Loads every asset from the manifest in src/assets.ts, then starts the game. */
export class BootScene extends Phaser.Scene {
  constructor() {
    super('Boot');
  }

  preload(): void {
    const label = this.add.text(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'Loading…', textStyle(28, COLORS.light)).setOrigin(0.5);
    this.load.on(Phaser.Loader.Events.PROGRESS, (v: number) => label.setText(`Loading… ${Math.round(v * 100)}%`));
    this.load.on(Phaser.Loader.Events.FILE_LOAD_ERROR, (file: Phaser.Loader.File) => {
      console.warn(`[assets] Could not load "${file.key}" from ${file.url}. Check the path in src/assets.ts.`);
    });
    preloadAssets(this);
  }

  create(): void {
    applyTextureFilters(this);
    this.scene.start('Game');
  }
}
