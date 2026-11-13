/**
 * Screen + play-field layout. Change these to reshape the arena.
 * Gameplay balance numbers live in src/data/, not here.
 */
export const GAME_WIDTH = 1280;
export const GAME_HEIGHT = 720;

/** Portrait play field in the middle of the landscape window. */
export const FIELD_WIDTH = 560;
export const FIELD_LEFT = (GAME_WIDTH - FIELD_WIDTH) / 2; // 360
export const FIELD_RIGHT = FIELD_LEFT + FIELD_WIDTH; // 920
export const FIELD_CENTER_X = FIELD_LEFT + FIELD_WIDTH / 2;

export const LAYOUT = {
  enemyY: 92,
  heroY: 614,
  wallTop: 650,
} as const;

/** Draw order (higher = on top). */
export const DEPTH = {
  background: 0,
  wall: 10,
  enemy: 20,
  hero: 30,
  shield: 35,
  projectile: 40,
  fx: 50,
  hud: 100,
  overlay: 200,
} as const;

export const FONT_FAMILY = '"Trebuchet MS", "Segoe UI", Verdana, sans-serif';

export const COLORS = {
  ink: '#3b2a1a',
  inkSoft: '#6e5a43',
  gold: '#b8801a',
  light: '#f6eed9',
  hpHigh: 0x5aa84f,
  hpMid: 0xe0a82e,
  hpLow: 0xc8452f,
  barBack: 0x3b2a1a,
  flashBounce: 0xfff3b0,
  flashFizzle: 0x8c8c8c,
  flashHit: 0xffffff,
  puffGray: 0xbdbdbd,
  dust: 0xc9b48a,
  bounceRing: 0xffd75e,
  overlay: 0x1d1408,
} as const;
