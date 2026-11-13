import Phaser from 'phaser';

/** Input map: action -> keys. Gameplay is keyboard only; the mouse is only for UI. */
export const INPUT_MAP = {
  move_left: ['A', 'LEFT'],
  move_right: ['D', 'RIGHT'],
  pause: ['ESC'],
} as const;

export type Action = keyof typeof INPUT_MAP;

export class InputActions {
  private readonly keys: Record<Action, Phaser.Input.Keyboard.Key[]>;

  constructor(scene: Phaser.Scene) {
    const keyboard = scene.input.keyboard!;
    const keys = {} as Record<Action, Phaser.Input.Keyboard.Key[]>;
    for (const action of Object.keys(INPUT_MAP) as Action[]) {
      keys[action] = INPUT_MAP[action].map((code) => keyboard.addKey(code));
    }
    this.keys = keys;
  }

  isDown(action: Action): boolean {
    return this.keys[action].some((k) => k.isDown);
  }

  justPressed(action: Action): boolean {
    // Check every key so each one's "just down" flag is consumed this frame.
    return this.keys[action].map((k) => Phaser.Input.Keyboard.JustDown(k)).some(Boolean);
  }
}
