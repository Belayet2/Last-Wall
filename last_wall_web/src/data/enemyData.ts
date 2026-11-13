import type { AssetKey } from '../assets';

/** More types (fast, heavy, boss) are added in step 4/5. */
export type EnemyType = 'thrower';

export interface EnemyStats {
  name: string;
  sprite: AssetKey;
  maxHp: number;
  /** Seconds between throws. */
  throwInterval: number;
  /** Random +/- fraction applied to each interval so enemies don't throw in sync. */
  throwJitter: number;
  projectileSpeed: number;
  /** Damage to the wall when this enemy's shot lands. */
  wallDamage: number;
  /** Damage this enemy's shot deals to enemies after the shield returns it. */
  returnedDamage: number;
  coinReward: number;
  /** Random aim error in degrees on top of the random wall target. */
  aimErrorDeg: number;
  /** Hitbox size (the sprite size is in src/assets.ts). */
  hitWidth: number;
  hitHeight: number;
}

export const ENEMY_DATA: Record<EnemyType, EnemyStats> = {
  thrower: {
    name: 'Thrower',
    sprite: 'enemy_thrower',
    maxHp: 3,
    throwInterval: 2.8,
    throwJitter: 0.25,
    projectileSpeed: 180,
    wallDamage: 10,
    returnedDamage: 1,
    coinReward: 5,
    aimErrorDeg: 4,
    hitWidth: 66,
    hitHeight: 58,
  },
};
