import Phaser from 'phaser';

/** Shortest-path interpolation between two angles (radians). */
export function lerpAngle(from: number, to: number, t: number): number {
  return from + Phaser.Math.Angle.Wrap(to - from) * t;
}

/** Mirror `v` off a surface with unit normal `n` (like Godot's Vector2.bounce). */
export function bounce(v: Phaser.Math.Vector2, n: Phaser.Math.Vector2): Phaser.Math.Vector2 {
  const d = v.dot(n);
  return new Phaser.Math.Vector2(v.x - 2 * d * n.x, v.y - 2 * d * n.y);
}

export function circleHitsRect(cx: number, cy: number, r: number, rect: Phaser.Geom.Rectangle): boolean {
  const nx = Phaser.Math.Clamp(cx, rect.left, rect.right);
  const ny = Phaser.Math.Clamp(cy, rect.top, rect.bottom);
  const dx = cx - nx;
  const dy = cy - ny;
  return dx * dx + dy * dy <= r * r;
}
