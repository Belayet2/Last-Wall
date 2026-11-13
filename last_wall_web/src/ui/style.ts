import Phaser from 'phaser';
import { COLORS, FONT_FAMILY } from '../config';

type TextStyle = Phaser.Types.GameObjects.Text.TextStyle;

export function textStyle(size: number, color: string = COLORS.ink, extra: TextStyle = {}): TextStyle {
  return { fontFamily: FONT_FAMILY, fontSize: `${size}px`, color, resolution: 2, ...extra };
}
