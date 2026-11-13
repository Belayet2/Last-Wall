import Phaser from 'phaser';
import { addSprite, setSpriteTexture } from '../assets';
import { DEPTH, FIELD_LEFT, FIELD_RIGHT, GAME_HEIGHT } from '../config';
import { PROJECTILE_DATA } from '../data/projectileData';

export type ProjectileState = 'hostile' | 'returned';

/**
 * Moved manually with a velocity vector (no physics engine).
 * hostile: hurts the wall, can be bounced by the shield.
 * returned: hurts enemies, ignores wall + shield.
 */
export class Projectile {
  state: ProjectileState = 'hostile';
  readonly sprite: Phaser.GameObjects.Image;
  readonly radius = PROJECTILE_DATA.radius;
  age = 0;
  dead = false;
  /** Set once the shield has touched it, so it can never be rolled twice. */
  shieldTouched = false;

  constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    readonly vel: Phaser.Math.Vector2,
    readonly wallDamage: number,
    readonly returnedDamage: number,
  ) {
    this.sprite = addSprite(scene, x, y, 'projectile_hostile').setDepth(DEPTH.projectile);
  }

  get x(): number {
    return this.sprite.x;
  }

  get y(): number {
    return this.sprite.y;
  }

  update(dt: number): void {
    this.age += dt;
    const s = this.sprite;
    s.x += this.vel.x * dt;
    s.y += this.vel.y * dt;
    if (this.state === 'hostile') s.rotation += PROJECTILE_DATA.spinSpeed * dt;

    // Solid side edges.
    if (s.x - this.radius < FIELD_LEFT) {
      s.x = FIELD_LEFT + this.radius;
      this.vel.x = Math.abs(this.vel.x);
    } else if (s.x + this.radius > FIELD_RIGHT) {
      s.x = FIELD_RIGHT - this.radius;
      this.vel.x = -Math.abs(this.vel.x);
    }

    const offscreen = s.y < -this.radius * 2 || s.y > GAME_HEIGHT + this.radius * 2;
    if (offscreen || this.age > PROJECTILE_DATA.lifetimeSec) this.kill();
  }

  makeReturned(newVel: Phaser.Math.Vector2): void {
    this.state = 'returned';
    this.vel.copy(newVel);
    setSpriteTexture(this.sprite, 'projectile_returned');
    this.sprite.rotation = 0;
  }

  kill(): void {
    if (this.dead) return;
    this.dead = true;
    this.sprite.destroy();
  }
}
