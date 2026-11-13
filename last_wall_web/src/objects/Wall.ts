import Phaser from 'phaser';
import { addSprite, setSpriteTexture, type AssetKey } from '../assets';
import { COLORS, DEPTH, FIELD_LEFT, FIELD_WIDTH, GAME_HEIGHT, LAYOUT } from '../config';
import { WALL_DATA } from '../data/wallData';

export type WallState = 'HELD' | 'DAMAGED' | 'FALLEN';

export const WallEvents = {
  HP_CHANGED: 'hp_changed',
  FALLEN: 'wall_fallen',
} as const;

/** Full-width wall at the bottom, behind the hero. Emits `wall_fallen` when HP hits 0. */
export class Wall extends Phaser.Events.EventEmitter {
  hp: number;
  state: WallState = 'HELD';
  readonly sprite: Phaser.GameObjects.Image;
  private readonly bar: Phaser.GameObjects.Graphics;
  private flashTimer?: Phaser.Time.TimerEvent;

  constructor(
    private readonly scene: Phaser.Scene,
    readonly maxHp: number,
    startHp: number = maxHp,
  ) {
    super();
    this.hp = startHp;
    this.sprite = addSprite(scene, FIELD_LEFT, LAYOUT.wallTop, 'wall_full').setOrigin(0, 0).setDepth(DEPTH.wall);
    this.bar = scene.add.graphics().setDepth(DEPTH.wall + 1);
    this.refresh();
  }

  get top(): number {
    return LAYOUT.wallTop;
  }

  get ratio(): number {
    return this.hp / this.maxHp;
  }

  damage(amount: number): void {
    if (this.state === 'FALLEN') return;
    this.hp = Math.max(0, this.hp - amount);
    this.refresh();
    this.flash();
    this.emit(WallEvents.HP_CHANGED, this.hp, this.maxHp);
    // Only reachable once: after this, state is FALLEN and damage() returns early.
    if (this.hp <= 0) this.emit(WallEvents.FALLEN);
  }

  private refresh(): void {
    const r = this.ratio;
    this.state = this.hp <= 0 ? 'FALLEN' : r < WALL_DATA.damagedBelow ? 'DAMAGED' : 'HELD';

    const look: AssetKey = r < WALL_DATA.brokenBelow ? 'wall_broken' : r < WALL_DATA.damagedBelow ? 'wall_cracked' : 'wall_full';
    if (this.sprite.texture.key !== look) setSpriteTexture(this.sprite, look);

    // Thin HP strip along the bottom of the wall.
    const x = FIELD_LEFT + 10;
    const w = FIELD_WIDTH - 20;
    const y = GAME_HEIGHT - 12;
    this.bar.clear();
    this.bar.fillStyle(COLORS.barBack, 0.8).fillRect(x, y, w, 6);
    this.bar.fillStyle(hpColor(r), 1).fillRect(x, y, w * r, 6);
  }

  private flash(): void {
    this.sprite.setTint(0xff9a8a);
    this.flashTimer?.remove();
    this.flashTimer = this.scene.time.delayedCall(WALL_DATA.flashMs, () => this.sprite.clearTint());
  }
}

export function hpColor(ratio: number): number {
  if (ratio >= WALL_DATA.damagedBelow) return COLORS.hpHigh;
  if (ratio >= WALL_DATA.brokenBelow) return COLORS.hpMid;
  return COLORS.hpLow;
}
