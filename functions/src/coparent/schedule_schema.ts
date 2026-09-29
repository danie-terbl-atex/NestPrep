import { z } from 'zod';

import { isoWeekday, parseIsoDate } from './custody_dates';

/**
 * The parenting schedule as it is stored and checked (household ADR-0004).
 *
 * A cycle of one to four weeks from a Monday, written as blocks — a side, the
 * week of the cycle, the weekdays — which the app turns into weekly
 * `RecurrenceRule`s and expands with the recurrence model every feature uses
 * (foundation ADR-0005). The server never expands it; it checks that every day
 * of the cycle belongs to exactly one home, which is what makes "who has the
 * child on Thursday" always have one answer.
 */

export const SIDES = ['a', 'b'] as const;
export type Side = (typeof SIDES)[number];

export const PATTERNS = ['alternatingWeeks', 'twoTwoThree', 'everyOtherWeekend', 'custom'] as const;

/** The member palette's names (design-system ADR-0003); a home is drawn in one. */
export const HOME_COLORS = [
  'violet',
  'pink',
  'coral',
  'amber',
  'lime',
  'mint',
  'teal',
  'sky',
  'indigo',
  'plum',
] as const;

export const MAX_CYCLE_WEEKS = 4;

export const side = z.enum(SIDES);

export const isoDate = z
  .string()
  .trim()
  .refine((value) => parseIsoDate(value) !== null, 'not a calendar date');

const block = z.object({
  side,
  weekOffset: z
    .number()
    .int()
    .min(0)
    .max(MAX_CYCLE_WEEKS - 1),
  weekdays: z.array(z.number().int().min(1).max(7)).min(1).max(7),
});
export type CustodyBlock = z.infer<typeof block>;

/** Whether the blocks cover every day of the cycle once and nothing outside it. */
export function coversEveryDayOnce(cycleWeeks: number, blocks: readonly CustodyBlock[]): boolean {
  const seen = new Set<string>();
  for (const { weekOffset, weekdays } of blocks) {
    if (weekOffset >= cycleWeeks) return false;
    for (const weekday of weekdays) {
      const key = `${String(weekOffset)}:${String(weekday)}`;
      if (seen.has(key)) return false;
      seen.add(key);
    }
  }
  return seen.size === cycleWeeks * 7;
}

export const custodySchedule = z
  .object({
    pattern: z.enum(PATTERNS),
    startsOn: isoDate.refine((value) => {
      const date = parseIsoDate(value);
      return date !== null && isoWeekday(date) === 1;
    }, 'a cycle starts on a Monday'),
    cycleWeeks: z.number().int().min(1).max(MAX_CYCLE_WEEKS),
    blocks: z
      .array(block)
      .min(1)
      .max(MAX_CYCLE_WEEKS * 7),
    // Minutes after midnight in the household's own time; null means "some
    // time that day".
    handoverMinute: z
      .number()
      .int()
      .min(0)
      .max(24 * 60 - 1)
      .nullable(),
  })
  .refine(
    (schedule) => coversEveryDayOnce(schedule.cycleWeeks, schedule.blocks),
    'every day of the cycle belongs to exactly one home',
  );
export type CustodySchedule = z.infer<typeof custodySchedule>;

export const home = z.object({
  name: z.string().trim().min(1).max(40),
  color: z.enum(HOME_COLORS),
});
export type Home = z.infer<typeof home>;
