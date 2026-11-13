import type { EnemyType } from './enemyData';

export interface WallLevel {
  wall: number;
  wallMaxHp: number;
  enemies: EnemyType[];
  obstacles: number;
}

export const TOTAL_WALLS = 5;

/** One row per wall. Step 1 only plays Wall 1; walls 2-5 arrive in steps 2 and 4. */
export const LEVEL_DATA: WallLevel[] = [
  { wall: 1, wallMaxHp: 150, enemies: ['thrower', 'thrower', 'thrower'], obstacles: 0 },
];
