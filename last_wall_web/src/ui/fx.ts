import Phaser from 'phaser';
import { COLORS, DEPTH } from '../config';
import { textStyle } from './style';

/** Small expanding, fading circle (fizzles, dust, pops). */
export function puff(scene: Phaser.Scene, x: number, y: number, color: number, radius = 12): void {
  const c = scene.add.circle(x, y, radius, color, 0.85).setDepth(DEPTH.fx);
  scene.tweens.add({
    targets: c,
    scale: 2.2,
    alpha: 0,
    duration: 260,
    ease: 'Quad.easeOut',
    onComplete: () => c.destroy(),
  });
}

/** Expanding ring, used for a successful shield bounce. */
export function ring(scene: Phaser.Scene, x: number, y: number, color: number = COLORS.bounceRing): void {
  const c = scene.add.circle(x, y, 10).setStrokeStyle(3, color).setDepth(DEPTH.fx);
  scene.tweens.add({
    targets: c,
    scale: 2.6,
    alpha: 0,
    duration: 220,
    ease: 'Quad.easeOut',
    onComplete: () => c.destroy(),
  });
}

/** Text that floats up and fades, e.g. "+5". */
export function floatText(scene: Phaser.Scene, x: number, y: number, text: string, color: string = COLORS.gold): void {
  const t = scene.add
    .text(x, y, text, textStyle(22, color, { fontStyle: 'bold', stroke: '#2a1c0e', strokeThickness: 4 }))
    .setOrigin(0.5)
    .setDepth(DEPTH.fx);
  scene.tweens.add({
    targets: t,
    y: y - 36,
    alpha: 0,
    duration: 800,
    ease: 'Cubic.easeOut',
    onComplete: () => t.destroy(),
  });
}
