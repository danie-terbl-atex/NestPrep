import { addDays } from '../documents/expiry_schedule';

/**
 * A child's run of days on which they earned stars (todos ADR-0003).
 *
 * Moved only when stars land: the same day leaves it, the day after the last
 * adds one, and anything later starts again at one. It is never moved back —
 * an unticked chore does not un-count a day, which the ADR accepts.
 */
export interface Streak {
  readonly streakDays: number;
  readonly bestStreak: number;
  /** `YYYY-MM-DD` in the household's zone, or null before the first star. */
  readonly streakLastDay: string | null;
}

export const NO_STREAK: Streak = { streakDays: 0, bestStreak: 0, streakLastDay: null };

export function nextStreak(streak: Streak, today: string): Streak {
  if (streak.streakLastDay === today) return streak;
  const continues = streak.streakLastDay !== null && addDays(streak.streakLastDay, 1) === today;
  const streakDays = continues ? streak.streakDays + 1 : 1;
  return {
    streakDays,
    bestStreak: Math.max(streak.bestStreak, streakDays),
    streakLastDay: today,
  };
}
