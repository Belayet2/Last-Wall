import Phaser from 'phaser';
import { GAME_HEIGHT, GAME_WIDTH } from './config';
import { BootScene } from './scenes/BootScene';
import { GameScene } from './scenes/GameScene';

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game',
  width: GAME_WIDTH,
  height: GAME_HEIGHT,
  backgroundColor: '#1d2b3a',
  banner: false,
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  // No sound yet. Step 6 adds a "Click to Start" screen, then audio can be turned on.
  audio: { noAudio: true },
  scene: [BootScene, GameScene],
});

// Dev-only handle for debugging in the browser console (stripped from production builds).
if (import.meta.env.DEV) (window as unknown as { game: Phaser.Game }).game = game;
