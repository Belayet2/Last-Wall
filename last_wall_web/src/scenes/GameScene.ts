import Phaser from 'phaser';
import { addSprite } from '../assets';
import { COLORS, DEPTH, FIELD_LEFT, FIELD_RIGHT, FIELD_WIDTH, LAYOUT } from '../config';
import { SHIELD_DATA } from '../data/heroData';
import { LEVEL_DATA } from '../data/levelData';
import { InputActions } from '../input';
import { Enemy } from '../objects/Enemy';
import { Hero } from '../objects/Hero';
import { Projectile } from '../objects/Projectile';
import { Wall, WallEvents } from '../objects/Wall';
import { GameState } from '../state/gameState';
import { floatText, puff, ring } from '../ui/fx';
import { Hud } from '../ui/Hud';
import { bounce, circleHitsRect, lerpAngle } from '../utils/math';

const { Vector2 } = Phaser.Math;

/** The play field. Step 1: Wall 1 only, win/lose restarts the scene. */
export class GameScene extends Phaser.Scene {
  private hero!: Hero;
  private wall!: Wall;
  private hud!: Hud;
  private actions!: InputActions;
  private enemies: Enemy[] = [];
  private projectiles: Projectile[] = [];
  private roundOver = false;
  private paused = false;

  constructor() {
    super('Game');
  }

  create(): void {
    // scene.restart() reuses this instance, so reset per-round fields here.
    GameState.reset();
    this.enemies = [];
    this.projectiles = [];
    this.roundOver = false;
    this.paused = false;

    const level = LEVEL_DATA[GameState.currentWall - 1];

    addSprite(this, FIELD_LEFT, 0, 'bg_field').setOrigin(0, 0).setDepth(DEPTH.background);
    addSprite(this, 0, 0, 'bg_side').setOrigin(0, 0).setDepth(DEPTH.background);
    addSprite(this, FIELD_RIGHT, 0, 'bg_side').setOrigin(0, 0).setFlipX(true).setDepth(DEPTH.background);

    this.wall = new Wall(this, level.wallMaxHp);
    this.hero = new Hero(this);

    const n = level.enemies.length;
    level.enemies.forEach((type, i) => {
      const x = FIELD_LEFT + (FIELD_WIDTH * (i + 1)) / (n + 1);
      this.enemies.push(new Enemy(this, x, LAYOUT.enemyY, type));
    });

    this.hud = new Hud(this, this.wall, level.wall);
    this.hud.setEnemiesLeft(n);
    this.actions = new InputActions(this);

    this.wall.once(WallEvents.FALLEN, () => this.endRound(false));
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => this.wall.removeAllListeners());
  }

  update(_time: number, deltaMs: number): void {
    if (this.actions.justPressed('pause') && !this.roundOver) this.togglePause();
    if (this.paused || this.roundOver) return;

    const dt = Math.min(deltaMs / 1000, 1 / 20);

    this.hero.update(dt, this.actions);

    for (const enemy of this.enemies) {
      if (enemy.tick(dt)) this.throwFrom(enemy);
    }

    for (const p of this.projectiles) {
      p.update(dt);
      if (!p.dead) this.checkCollisions(p);
      if (this.roundOver) return;
    }
    this.projectiles = this.projectiles.filter((p) => !p.dead);
  }

  // ---------------------------------------------------------------- throwing

  private throwFrom(enemy: Enemy): void {
    const s = enemy.stats;
    const startX = enemy.x;
    const startY = enemy.y + s.hitHeight / 2;
    // Aim at a random point along the wall, plus a little error.
    const targetX = Phaser.Math.FloatBetween(FIELD_LEFT + 10, FIELD_RIGHT - 10);
    const angle =
      Math.atan2(LAYOUT.wallTop - startY, targetX - startX) +
      Phaser.Math.DegToRad(Phaser.Math.FloatBetween(-s.aimErrorDeg, s.aimErrorDeg));
    const vel = new Vector2(Math.cos(angle), Math.sin(angle)).scale(s.projectileSpeed);
    this.projectiles.push(new Projectile(this, startX, startY, vel, s.wallDamage, s.returnedDamage));
  }

  // -------------------------------------------------------------- collisions

  private checkCollisions(p: Projectile): void {
    if (p.state === 'hostile') {
      const shield = this.hero.shield;
      if (!p.shieldTouched && p.vel.y > 0 && circleHitsRect(p.x, p.y, p.radius, shield.bounds)) {
        this.onShieldHit(p);
        return;
      }
      if (p.y + p.radius >= this.wall.top) {
        puff(this, p.x, this.wall.top + 6, COLORS.dust, 14);
        p.kill();
        this.wall.damage(p.wallDamage);
      }
      return;
    }

    // Returned: hurts enemies, ignores the wall and the shield.
    for (const enemy of this.enemies) {
      if (!enemy.alive || !circleHitsRect(p.x, p.y, p.radius, enemy.bounds)) continue;
      puff(this, p.x, p.y, COLORS.bounceRing, 10);
      p.kill();
      if (enemy.hit(p.returnedDamage)) this.onEnemyKilled(enemy);
      break;
    }
  }

  private onShieldHit(p: Projectile): void {
    p.shieldTouched = true;
    const shield = this.hero.shield;

    if (Math.random() >= GameState.bounceRate) {
      // FIZZLE: blocked, not returned, no wall damage.
      shield.flash(COLORS.flashFizzle);
      puff(this, p.x, p.y, COLORS.puffGray);
      p.kill();
      return;
    }

    // BOUNCE
    const dir = this.bounceDirection(p);
    const speed = p.vel.length() * SHIELD_DATA.bounceSpeedMultiplier;
    p.makeReturned(dir.scale(speed));
    p.sprite.y = shield.bounds.top - p.radius - 1;
    shield.flash(COLORS.flashBounce);
    ring(this, p.x, p.y);
  }

  private bounceDirection(p: Projectile): Phaser.Math.Vector2 {
    const offset = this.hero.shield.hitOffset(p.x);
    const tilt = Phaser.Math.DegToRad(offset * SHIELD_DATA.maxTiltDeg);
    const normal = new Vector2(Math.sin(tilt), -Math.cos(tilt));

    let dir: Phaser.Math.Vector2;
    if (SHIELD_DATA.bounceMode === 'reflect') {
      dir = bounce(p.vel.clone().normalize(), normal);
      if (dir.y > -0.2) dir.y = -0.2; // always leave upward
      dir.normalize();
    } else {
      dir = normal;
    }

    // Aim accuracy: steer toward the nearest living enemy.
    const target = this.nearestEnemy(p.x, p.y);
    if (target && GameState.aimAccuracy > 0) {
      const toTarget = Math.atan2(target.y - p.y, target.x - p.x);
      const a = lerpAngle(dir.angle(), toTarget, GameState.aimAccuracy);
      dir = new Vector2(Math.cos(a), Math.sin(a));
    }
    return dir;
  }

  private nearestEnemy(x: number, y: number): Enemy | undefined {
    let best: Enemy | undefined;
    let bestD = Infinity;
    for (const e of this.enemies) {
      if (!e.alive) continue;
      const d = Phaser.Math.Distance.Squared(x, y, e.x, e.y);
      if (d < bestD) {
        bestD = d;
        best = e;
      }
    }
    return best;
  }

  // ------------------------------------------------------------- round flow

  private onEnemyKilled(enemy: Enemy): void {
    GameState.addCoins(enemy.stats.coinReward);
    floatText(this, enemy.x, enemy.y - 20, `+${enemy.stats.coinReward}`);
    const left = this.enemies.filter((e) => e.alive).length;
    this.hud.setEnemiesLeft(left);
    if (left === 0) this.endRound(true);
  }

  private endRound(won: boolean): void {
    if (this.roundOver) return;
    this.roundOver = true;

    for (const p of this.projectiles) {
      if (!p.dead) puff(this, p.x, p.y, COLORS.puffGray, 8);
      p.kill();
    }
    this.projectiles = [];

    if (won) {
      this.hud.showBanner('Wall Held!', 'Every thrower is down.', 'Click to play again', true);
    } else {
      this.hud.showBanner('Wall Fell!', 'The ships broke through.', 'Click to try again', false);
    }
    this.time.delayedCall(500, () => this.input.once(Phaser.Input.Events.POINTER_DOWN, () => this.scene.restart()));
  }

  private togglePause(): void {
    this.paused = !this.paused;
    this.time.paused = this.paused;
    if (this.paused) this.tweens.pauseAll();
    else this.tweens.resumeAll();
    this.hud.showPaused(this.paused);
  }
}
