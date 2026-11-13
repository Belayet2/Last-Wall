import Phaser from 'phaser';
import { HERO_DATA, SHIELD_DATA } from '../data/heroData';

export const GameEvents = {
  COINS_CHANGED: 'coins_changed',
} as const;

/**
 * Global run state (the web version of a Godot autoload).
 * Holds coins, current wall and the hero's current stats. Other code listens to its events.
 */
class GameStateStore extends Phaser.Events.EventEmitter {
  coins = 0;
  currentWall = 1;
  bounceRate = SHIELD_DATA.bounceRate;
  aimAccuracy = SHIELD_DATA.aimAccuracy;
  moveSpeed = HERO_DATA.moveSpeed;

  reset(): void {
    this.coins = 0;
    this.currentWall = 1;
    this.bounceRate = SHIELD_DATA.bounceRate;
    this.aimAccuracy = SHIELD_DATA.aimAccuracy;
    this.moveSpeed = HERO_DATA.moveSpeed;
    this.emit(GameEvents.COINS_CHANGED, this.coins);
  }

  addCoins(amount: number): void {
    this.coins += amount;
    this.emit(GameEvents.COINS_CHANGED, this.coins);
  }
}

export const GameState = new GameStateStore();
