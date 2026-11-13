import Phaser from 'phaser';
import { addSprite } from '../assets';
import { DEPTH, FIELD_CENTER_X, FIELD_LEFT, FIELD_RIGHT, LAYOUT } from '../config';
import { HERO_DATA, SHIELD_DATA } from '../data/heroData';
import type { InputActions } from '../input';
import { GameState } from '../state/gameState';
import { Shield } from './Shield';

/** Moves left/right only. Has no health; projectiles pass through the body. */
export class Hero {
  readonly sprite: Phaser.GameObjects.Image;
  readonly shield: Shield;
  private walkTime = 0;

  constructor(scene: Phaser.Scene) {
    this.sprite = addSprite(scene, FIELD_CENTER_X, LAYOUT.heroY, 'hero').setDepth(DEPTH.hero);
    this.shield = new Shield(scene, FIELD_CENTER_X, LAYOUT.heroY - SHIELD_DATA.offsetY);
  }

  get x(): number {
    return this.sprite.x;
  }

  update(dt: number, input: InputActions): void {
    let dir = 0;
    if (input.isDown('move_left')) dir -= 1;
    if (input.isDown('move_right')) dir += 1;

    // Keep both the body and the (wider) shield inside the field.
    const half = Math.max(this.sprite.displayWidth, this.shield.width) / 2;
    const x = Phaser.Math.Clamp(this.x + dir * GameState.moveSpeed * dt, FIELD_LEFT + half, FIELD_RIGHT - half);

    this.walkTime = dir !== 0 ? this.walkTime + dt : 0;
    const bob = Math.abs(Math.sin(this.walkTime * HERO_DATA.walkBobSpeed)) * -HERO_DATA.walkBobPx;

    this.sprite.setPosition(x, LAYOUT.heroY + bob);
    this.shield.setPosition(x, LAYOUT.heroY - SHIELD_DATA.offsetY);
  }
}
