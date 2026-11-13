import Phaser from 'phaser';
import { addSprite } from '../assets';
import { COLORS, DEPTH } from '../config';
import { ENEMY_DATA, type EnemyStats, type EnemyType } from '../data/enemyData';

/** Stands still at the top and throws. All enemy types share this class; they differ only by data. */
export class Enemy {
  readonly stats: EnemyStats;
  readonly sprite: Phaser.GameObjects.Image;
  hp: number;
  alive = true;
  private readonly bar: Phaser.GameObjects.Graphics;
  private throwTimer: number;
  private flashTimer?: Phaser.Time.TimerEvent;

  constructor(
    private readonly scene: Phaser.Scene,
    x: number,
    y: number,
    readonly type: EnemyType,
  ) {
    this.stats = ENEMY_DATA[type];
    this.hp = this.stats.maxHp;
    this.sprite = addSprite(scene, x, y, this.stats.sprite).setDepth(DEPTH.enemy);
    this.bar = scene.add.graphics().setDepth(DEPTH.enemy + 1);
    // Stagger the first throw so the row doesn't fire in sync.
    this.throwTimer = this.stats.throwInterval * Phaser.Math.FloatBetween(0.35, 1);

    // Gentle bob on the waves.
    scene.tweens.add({
      targets: this.sprite,
      y: y + 4,
      duration: Phaser.Math.Between(1100, 1500),
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
    });
    this.drawBar();
  }

  get x(): number {
    return this.sprite.x;
  }

  get y(): number {
    return this.sprite.y;
  }

  get bounds(): Phaser.Geom.Rectangle {
    const { hitWidth: w, hitHeight: h } = this.stats;
    return new Phaser.Geom.Rectangle(this.x - w / 2, this.y - h / 2, w, h);
  }

  /** Advances the throw timer. Returns true when the enemy should throw this frame. */
  tick(dt: number): boolean {
    if (!this.alive) return false;
    this.drawBar();
    this.throwTimer -= dt;
    if (this.throwTimer > 0) return false;
    const jitter = this.stats.throwJitter;
    this.throwTimer = this.stats.throwInterval * (1 + Phaser.Math.FloatBetween(-jitter, jitter));
    return true;
  }

  /** Applies damage. Returns true if this hit killed the enemy. */
  hit(damage: number): boolean {
    if (!this.alive) return false;
    this.hp -= damage;
    if (this.hp <= 0) {
      this.die();
      return true;
    }
    this.sprite.setTintFill(COLORS.flashHit);
    this.flashTimer?.remove();
    this.flashTimer = this.scene.time.delayedCall(80, () => this.sprite.clearTint());
    this.drawBar();
    return false;
  }

  private die(): void {
    this.alive = false;
    this.flashTimer?.remove();
    this.bar.destroy();
    this.scene.tweens.killTweensOf(this.sprite);
    this.sprite.clearTint();
    this.scene.tweens.add({
      targets: this.sprite,
      scaleX: this.sprite.scaleX * 1.35,
      scaleY: this.sprite.scaleY * 1.35,
      alpha: 0,
      angle: Phaser.Math.Between(-25, 25),
      duration: 280,
      ease: 'Back.easeIn',
      onComplete: () => this.sprite.destroy(),
    });
  }

  private drawBar(): void {
    const w = 46;
    const x = this.x - w / 2;
    const y = this.y - this.sprite.displayHeight / 2 - 10;
    const r = Math.max(0, this.hp / this.stats.maxHp);
    this.bar.clear();
    this.bar.fillStyle(COLORS.barBack, 0.8).fillRect(x, y, w, 6);
    this.bar.fillStyle(COLORS.hpLow, 1).fillRect(x + 1, y + 1, (w - 2) * r, 4);
  }
}
