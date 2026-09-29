import { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { parseInput } from '../../src/household/parse_input';
import {
  addDays,
  daysBetween,
  isWithin,
  isoDaysFrom,
  isoOf,
  isoWeekday,
  parseIsoDate,
} from '../../src/coparent/custody_dates';
import { coversEveryDayOnce, custodySchedule } from '../../src/coparent/schedule_schema';
import { ALTERNATING, TWO_TWO_THREE } from '../coparent_fixtures';

/**
 * The parenting schedule's shape (household ADR-0004): a cycle of one to
 * four weeks from a Monday, every day of it belonging to exactly one home.
 * The client builds it from presets and expands it with the recurrence
 * model; the server only refuses a cycle with a hole or an overlap in it.
 */

const ALL_WEEK = [1, 2, 3, 4, 5, 6, 7];

describe('a schedule covers every day of its cycle exactly once', () => {
  it('accepts alternating weeks and 2-2-3', () => {
    expect(coversEveryDayOnce(ALTERNATING.cycleWeeks, ALTERNATING.blocks)).toBe(true);
    expect(coversEveryDayOnce(TWO_TWO_THREE.cycleWeeks, TWO_TWO_THREE.blocks)).toBe(true);
  });

  it('refuses a hole — a Thursday nobody has', () => {
    expect(
      coversEveryDayOnce(1, [
        { side: 'a', weekOffset: 0, weekdays: [1, 2, 3] },
        { side: 'b', weekOffset: 0, weekdays: [5, 6, 7] },
      ]),
    ).toBe(false);
  });

  it('refuses an overlap — a Wednesday both homes have', () => {
    expect(
      coversEveryDayOnce(1, [
        { side: 'a', weekOffset: 0, weekdays: [1, 2, 3] },
        { side: 'b', weekOffset: 0, weekdays: [3, 4, 5, 6, 7] },
      ]),
    ).toBe(false);
  });

  it('refuses a block in a week the cycle does not have', () => {
    expect(
      coversEveryDayOnce(1, [
        { side: 'a', weekOffset: 0, weekdays: ALL_WEEK },
        { side: 'b', weekOffset: 1, weekdays: [1] },
      ]),
    ).toBe(false);
  });

  it('refuses one week of blocks for a two-week cycle', () => {
    expect(coversEveryDayOnce(2, [{ side: 'a', weekOffset: 0, weekdays: ALL_WEEK }])).toBe(false);
  });
});

describe('the stored schedule', () => {
  it('parses the presets as they are sent', () => {
    expect(() => parseInput(custodySchedule, ALTERNATING)).not.toThrow();
    expect(() => parseInput(custodySchedule, TWO_TWO_THREE)).not.toThrow();
  });

  it('starts on a Monday, because weeks are counted from one', () => {
    expect(() => parseInput(custodySchedule, { ...ALTERNATING, startsOn: '2026-09-29' })).toThrow(
      HttpsError,
    );
  });

  it('refuses a day that is not in the calendar', () => {
    expect(() => parseInput(custodySchedule, { ...ALTERNATING, startsOn: '2026-02-30' })).toThrow(
      HttpsError,
    );
  });

  for (const [label, change] of [
    ['a five-week cycle', { cycleWeeks: 5 }],
    ['a pattern this build does not know', { pattern: 'everyThirdTuesday' }],
    ['a handover time past midnight', { handoverMinute: 24 * 60 }],
    ['a third home', { blocks: [{ side: 'c', weekOffset: 0, weekdays: ALL_WEEK }] }],
    ['a weekday eight', { blocks: [{ side: 'a', weekOffset: 0, weekdays: [8] }] }],
  ] as const) {
    it(`refuses ${label}`, () => {
      expect(() => parseInput(custodySchedule, { ...ALTERNATING, ...change })).toThrow(HttpsError);
    });
  }
});

describe('calendar dates', () => {
  it('parse only real days', () => {
    expect(parseIsoDate('2028-02-29')).not.toBeNull();
    expect(parseIsoDate('2027-02-29')).toBeNull();
    expect(parseIsoDate('2026-13-01')).toBeNull();
    expect(parseIsoDate('29/09/2026')).toBeNull();
  });

  it('count days across a daylight-saving change without drifting', () => {
    const start = parseIsoDate('2026-03-27');
    const end = parseIsoDate('2026-04-03');
    if (start === null || end === null) throw new Error('fixture dates');
    expect(daysBetween(start, end)).toBe(7);
    expect(isoOf(addDays(start, 7))).toBe('2026-04-03');
  });

  it('number weekdays as the recurrence model does', () => {
    const monday = parseIsoDate('2026-09-28');
    const sunday = parseIsoDate('2026-10-04');
    if (monday === null || sunday === null) throw new Error('fixture dates');
    expect(isoWeekday(monday)).toBe(1);
    expect(isoWeekday(sunday)).toBe(7);
  });

  it('list every day of a range, inclusive', () => {
    const from = parseIsoDate('2026-10-02');
    const to = parseIsoDate('2026-10-04');
    if (from === null || to === null) throw new Error('fixture dates');
    expect(isoDaysFrom(from, to)).toEqual(['2026-10-02', '2026-10-03', '2026-10-04']);
  });

  it('allow a day either side of a window for the gap between UTC and a household', () => {
    const now = new Date('2026-09-29T10:00:00Z');
    const day = (iso: string): Date => parseIsoDate(iso) ?? new Date(NaN);
    expect(isWithin(day('2026-09-21'), 7, 365, now)).toBe(true);
    expect(isWithin(day('2026-09-20'), 7, 365, now)).toBe(false);
    expect(isWithin(day('2027-09-30'), 7, 365, now)).toBe(true);
    expect(isWithin(day('2027-10-01'), 7, 365, now)).toBe(false);
  });
});
