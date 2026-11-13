import Phaser from 'phaser';
import { addSprite } from '../assets';
import { DEPTH } from '../config';
import { SHIELD_DATA } from '../data/heroData';

/** Flat horizontal paddle. Never rotates; it only moves with the hero. */
export class Shield {
  readonly sprite: Phaser.GameObjects.Image;
  readonly width = SHIELD_DATA.width;
  readonly height = SHIELD_DATA.height;
  private flashTimer?: Phaser.Time.TimerEvent;

  constructor(
    private readonly scene: Phaser.Scene,
    x: number,
    y: number,
  ) {
    this.sprite = addSprite(scene, x, y, 'shield').setDepth(DEPTH.shield);
  }

  get x(): number {
    return this.sprite.x;
  }

  get y(): number {
    return this.sprite.y;
  }

  setPosition(x: number, y: number): void {
    this.sprite.setPosition(x, y);
  }

  get bounds(): Phaser.Geom.Rectangle {
    return new Phaser.Geom.Rectangle(this.x - this.width / 2, this.y - this.height / 2, this.width, this.height);
  }

  /** -1 (left edge) .. 0 (center) .. 1 (right edge). */
  hitOffset(px: number): number {
    return Phaser.Math.Clamp((px - this.x) / (this.width / 2), -1, 1);
  }

  flash(color: number): void {
    this.sprite.setTintFill(color);
    this.flashTimer?.remove();
    this.flashTimer = this.scene.time.delayedCall(SHIELD_DATA.flashMs, () => this.sprite.clearTint());
  }
}
