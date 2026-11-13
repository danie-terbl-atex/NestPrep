export const AVATAR_STAGES = [0, 1, 2, 3] as const;
export type AvatarStage = (typeof AVATAR_STAGES)[number];

export const ADULT_STAGE: AvatarStage = 3;

/**
 * A kid's Nestling from their stars (avatars ADR-0004): an egg until the first
 * star, then grown by the best streak, which only rises, so it never shrinks.
 * `bestStreak` counts too because unticked chores can take `earned` back to 0.
 */
export function starStage(stars: {
  readonly earned: number;
  readonly bestStreak: number;
}): AvatarStage {
  if (stars.bestStreak >= 7) return 3;
  if (stars.bestStreak >= 3) return 2;
  if (stars.earned >= 1 || stars.bestStreak >= 1) return 1;
  return 0;
}

export function isAvatarStage(value: unknown): value is AvatarStage {
  return typeof value === 'number' && (AVATAR_STAGES as readonly number[]).includes(value);
}
