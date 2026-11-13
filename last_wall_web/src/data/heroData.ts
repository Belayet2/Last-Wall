/** Hero + shield balance numbers. Shop upgrades (step 2) will add on top of these base values. */

export const HERO_DATA = {
  /** Base move speed in px/s. */
  moveSpeed: 220,
  /** Tiny walk bob, purely visual. */
  walkBobPx: 1.5,
  walkBobSpeed: 18,
};

/**
 * 'paddle'  = the projectile leaves along the tilted normal: center hit = straight up, edge hit = 40° sideways.
 *             Predictable, so the player can aim by positioning the hero.
 * 'reflect' = true mirror bounce (velocity.bounce(normal)); angles double and depend on the incoming angle.
 */
export type BounceMode = 'paddle' | 'reflect';

export const SHIELD_DATA = {
  /** Distance above the hero's center. */
  offsetY: 40,
  /** Hitbox size (the sprite size is in src/assets.ts). */
  width: 110,
  height: 16,
  /** Max tilt of the bounce normal at the very edge of the shield. */
  maxTiltDeg: 40,
  /** Chance (0..1) that a hostile projectile is bounced back instead of fizzling. */
  bounceRate: 0.4,
  /** 0..1, how strongly a bounced projectile is steered toward the nearest enemy. */
  aimAccuracy: 0.0,
  /** Speed multiplier applied on a successful bounce. */
  bounceSpeedMultiplier: 1.25,
  bounceMode: 'paddle' as BounceMode,
  flashMs: 110,
};
