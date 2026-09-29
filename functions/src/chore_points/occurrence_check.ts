import { z } from 'zod';

import { dayNumber } from '../documents/expiry_schedule';

/**
 * Whether a day is really an occurrence of a chore (todos ADR-0003).
 *
 * The rules accept a completion for any date whose id matches, so a date is
 * only proof of a chore once this says so — otherwise a child could tick "Make
 * your bed" for every day of last year and be paid for each.
 *
 * **This is the server's copy of `app/lib/shared/recurrence/
 * recurrence_expansion.dart`**, asked one question instead of expanding a
 * window: same frequencies, same interval arithmetic, weeks counted from the
 * Monday of the first occurrence, a month too short for the day skipped rather
 * than moved, and a rule this build cannot read treated as happening once on
 * its first day (`BE-10`). `test/unit/chore_points_occurrence.test.ts` walks
 * the same cases the Dart tests do.
 */

const MAX_INTERVAL = 366;

/** A stored rule, exactly as the Flutter client writes one. */
export const storedRecurrence = z.object({
  frequency: z.enum(['daily', 'weekly', 'monthly']),
  interval: z.number().int().default(1),
  weekdays: z.array(z.number().int()).default([]),
  until: z.string().nullable().default(null),
});
export type StoredRecurrence = z.infer<typeof storedRecurrence>;

function isExpandable(rule: StoredRecurrence): boolean {
  return (
    rule.interval >= 1 &&
    rule.interval <= MAX_INTERVAL &&
    rule.weekdays.every((day) => day >= 1 && day <= 7) &&
    (rule.frequency !== 'weekly' || rule.weekdays.length <= 7)
  );
}

/** ISO weekday of a day number (days since 1970-01-01, a Thursday). */
function weekdayOf(day: number): number {
  return ((((day + 3) % 7) + 7) % 7) + 1;
}

function mondayOf(day: number): number {
  return day - (weekdayOf(day) - 1);
}

function partsOf(iso: string): { year: number; month: number; day: number } {
  const [year, month, day] = iso.split('-').map(Number);
  return { year: year ?? 0, month: month ?? 0, day: day ?? 0 };
}

/**
 * True when [date] is an occurrence of a thing that first happens on
 * [firstDate] and repeats by [rule] (null: once). Every date is `YYYY-MM-DD`;
 * anything that is not a real calendar day is not an occurrence.
 */
export function isOccurrence(
  firstDate: string,
  rule: StoredRecurrence | null,
  date: string,
): boolean {
  const first = dayNumber(firstDate);
  const day = dayNumber(date);
  if (first === undefined || day === undefined) return false;
  if (rule === null || !isExpandable(rule)) return day === first;
  if (day < first) return false;
  if (rule.until !== null) {
    const until = dayNumber(rule.until);
    if (until !== undefined && day > until) return false;
  }

  switch (rule.frequency) {
    case 'daily':
      return (day - first) % rule.interval === 0;
    case 'weekly': {
      const weekdays = rule.weekdays.length === 0 ? [weekdayOf(first)] : rule.weekdays;
      if (!weekdays.includes(weekdayOf(day))) return false;
      const weeks = (mondayOf(day) - mondayOf(first)) / 7;
      return weeks % rule.interval === 0;
    }
    case 'monthly': {
      const a = partsOf(firstDate);
      const b = partsOf(date);
      if (a.day !== b.day) return false;
      const months = (b.year - a.year) * 12 + (b.month - a.month);
      return months % rule.interval === 0;
    }
  }
}
