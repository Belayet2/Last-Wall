import Phaser from 'phaser';
import { addSprite } from '../assets';
import { COLORS, DEPTH, FIELD_LEFT, FIELD_RIGHT, FIELD_WIDTH, GAME_HEIGHT, GAME_WIDTH } from '../config';
import { TOTAL_WALLS } from '../data/levelData';
import { hpColor, Wall, WallEvents } from '../objects/Wall';
import { GameEvents, GameState } from '../state/gameState';
import { textStyle } from './style';

const LEFT_X = 40; // content start inside the left panel
const LEFT_W = FIELD_LEFT - 80;
const RIGHT_X = FIELD_RIGHT + 48;
const RIGHT_W = GAME_WIDTH - FIELD_RIGHT - 88;

/** Side-panel HUD: wall HP, coins, enemies left, stats, controls. Also shows banners. */
export class Hud {
  private readonly hpBar: Phaser.GameObjects.Graphics;
  private readonly hpText: Phaser.GameObjects.Text;
  private readonly coinText: Phaser.GameObjects.Text;
  private readonly enemiesText: Phaser.GameObjects.Text;
  private readonly statsText: Phaser.GameObjects.Text;
  private pauseGroup?: Phaser.GameObjects.Container;

  constructor(
    private readonly scene: Phaser.Scene,
    private readonly wall: Wall,
    wallNumber: number,
  ) {
    const add = scene.add;
    const d = DEPTH.hud;

    // ---- Left panel ----
    add.text(LEFT_X, 44, 'LAST WALL', textStyle(38, COLORS.ink, { fontStyle: 'bold' })).setDepth(d);
    add.text(LEFT_X, 90, 'Bounce it back.', textStyle(17, COLORS.inkSoft, { fontStyle: 'italic' })).setDepth(d);

    add.text(LEFT_X, 150, `WALL ${wallNumber} / ${TOTAL_WALLS}`, textStyle(24, COLORS.ink, { fontStyle: 'bold' })).setDepth(d);

    add.text(LEFT_X, 196, 'Wall HP', textStyle(16, COLORS.inkSoft)).setDepth(d);
    this.hpBar = add.graphics().setDepth(d);
    this.hpText = add
      .text(LEFT_X + LEFT_W / 2, 233, '', textStyle(15, COLORS.light, { fontStyle: 'bold' }))
      .setOrigin(0.5)
      .setDepth(d + 1);

    addSprite(scene, LEFT_X + 11, 290, 'coin').setDepth(d);
    this.coinText = add.text(LEFT_X + 30, 278, '', textStyle(22, COLORS.gold, { fontStyle: 'bold' })).setDepth(d);

    this.enemiesText = add.text(LEFT_X, 326, '', textStyle(20, COLORS.ink)).setDepth(d);

    add.text(LEFT_X, 400, 'HERO', textStyle(16, COLORS.inkSoft)).setDepth(d);
    this.statsText = add.text(LEFT_X, 424, '', textStyle(17, COLORS.ink, { lineSpacing: 6 })).setDepth(d);

    // ---- Right panel ----
    add.text(RIGHT_X, 44, 'HOW TO PLAY', textStyle(22, COLORS.ink, { fontStyle: 'bold' })).setDepth(d);
    add
      .text(
        RIGHT_X,
        86,
        [
          'A / D  or  ← / →   move',
          'Esc   pause',
          '',
          'Your shield bounces rocks back at the ships.',
          '',
          'Hit with the shield EDGE to send the shot sideways. Hit with the CENTER to send it straight up.',
          '',
          'Gold flash = bounced.',
          'Gray flash = blocked, but not returned.',
          '',
          'Rocks you miss hit the wall. If the wall falls, you lose.',
        ].join('\n'),
        textStyle(16, COLORS.ink, { wordWrap: { width: RIGHT_W }, lineSpacing: 4 }),
      )
      .setDepth(d);

    // ---- Listeners ----
    wall.on(WallEvents.HP_CHANGED, this.drawHp, this);
    GameState.on(GameEvents.COINS_CHANGED, this.setCoins, this);
    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      GameState.off(GameEvents.COINS_CHANGED, this.setCoins, this);
      wall.off(WallEvents.HP_CHANGED, this.drawHp, this);
    });

    this.drawHp();
    this.setCoins(GameState.coins);
    this.refreshStats();
  }

  setEnemiesLeft(n: number): void {
    this.enemiesText.setText(`Enemies left: ${n}`);
  }

  refreshStats(): void {
    this.statsText.setText(
      [
        `Bounce chance  ${Math.round(GameState.bounceRate * 100)}%`,
        `Aim assist       ${Math.round(GameState.aimAccuracy * 100)}%`,
        `Move speed     ${GameState.moveSpeed}`,
      ].join('\n'),
    );
  }

  private setCoins(coins: number): void {
    this.coinText.setText(`${coins}`);
  }

  private drawHp(): void {
    const r = this.wall.hp / this.wall.maxHp;
    const y = 220;
    this.hpBar.clear();
    this.hpBar.fillStyle(COLORS.barBack, 1).fillRoundedRect(LEFT_X, y, LEFT_W, 26, 6);
    if (r > 0) this.hpBar.fillStyle(hpColor(r), 1).fillRoundedRect(LEFT_X + 3, y + 3, Math.max(8, (LEFT_W - 6) * r), 20, 4);
    this.hpText.setText(`${Math.ceil(this.wall.hp)} / ${this.wall.maxHp}`);
  }

  showPaused(show: boolean): void {
    this.pauseGroup?.destroy();
    this.pauseGroup = undefined;
    if (!show) return;
    const cx = FIELD_LEFT + FIELD_WIDTH / 2;
    const bg = this.scene.add.rectangle(cx, GAME_HEIGHT / 2, FIELD_WIDTH, GAME_HEIGHT, COLORS.overlay, 0.45);
    const t = this.scene.add
      .text(cx, GAME_HEIGHT / 2, 'PAUSED\n\nEsc to resume', textStyle(30, COLORS.light, { fontStyle: 'bold', align: 'center' }))
      .setOrigin(0.5);
    this.pauseGroup = this.scene.add.container(0, 0, [bg, t]).setDepth(DEPTH.overlay);
  }

  /** Big centered message over the play field. */
  showBanner(title: string, subtitle: string, prompt: string, won: boolean): void {
    const cx = FIELD_LEFT + FIELD_WIDTH / 2;
    const cy = GAME_HEIGHT / 2 - 40;
    const bg = this.scene.add.rectangle(cx, GAME_HEIGHT / 2, FIELD_WIDTH, GAME_HEIGHT, COLORS.overlay, 0.55);
    const panel = this.scene.add
      .rectangle(cx, cy, 420, 220, 0xf3ead3, 1)
      .setStrokeStyle(4, won ? 0xb8801a : 0x8c2d22);
    const titleText = this.scene.add
      .text(cx, cy - 50, title, textStyle(46, won ? COLORS.gold : '#9b2f22', { fontStyle: 'bold', stroke: '#2a1c0e', strokeThickness: 2 }))
      .setOrigin(0.5);
    const sub = this.scene.add.text(cx, cy + 10, subtitle, textStyle(18, COLORS.ink)).setOrigin(0.5);
    const promptText = this.scene.add.text(cx, cy + 62, prompt, textStyle(18, COLORS.inkSoft, { fontStyle: 'bold' })).setOrigin(0.5);

    const group = this.scene.add.container(0, 0, [bg, panel, titleText, sub, promptText]).setDepth(DEPTH.overlay);
    group.setAlpha(0);
    this.scene.tweens.add({ targets: group, alpha: 1, duration: 250 });
    this.scene.tweens.add({ targets: promptText, alpha: 0.35, duration: 700, yoyo: true, repeat: -1, delay: 400 });
  }
}
