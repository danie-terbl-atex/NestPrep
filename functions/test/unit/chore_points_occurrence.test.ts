import { describe, expect, it } from 'vitest';

import { isOccurrence, type StoredRecurrence } from '../../src/chore_points/occurrence_check';

/**
 * The server's answer to "is this day really one of the chore's days" (todos
 * ADR-0003) — the same answer `recurrence_expansion.dart` gives the child's
 * screen, or a child could be paid for a day the app never showed them, or
 * refused for one it did.
 */

const rule = (
  partial: Partial<StoredRecurrence> & Pick<StoredRecurrence, 'frequency'>,
): StoredRecurrence => ({
  interval: 1,
  weekdays: [],
  until: null,
  ...partial,
});

describe('a chore with no rule', () => {
  it('happens on its own day and no other', () => {
    expect(isOccurrence('2026-09-29', null, '2026-09-29')).toBe(true);
    expect(isOccurrence('2026-09-29', null, '2026-09-30')).toBe(false);
    expect(isOccurrence('2026-09-29', null, '2026-09-28')).toBe(false);
  });
});

describe('daily', () => {
  it('every day from the first, never before it', () => {
    const daily = rule({ frequency: 'daily' });
    expect(isOccurrence('2026-09-01', daily, '2026-09-01')).toBe(true);
    expect(isOccurrence('2026-09-01', daily, '2026-09-29')).toBe(true);
    expect(isOccurrence('2026-09-01', daily, '2026-08-31')).toBe(false);
  });

  it('every third day counts from the first', () => {
    const everyThird = rule({ frequency: 'daily', interval: 3 });
    expect(isOccurrence('2026-09-01', everyThird, '2026-09-04')).toBe(true);
    expect(isOccurrence('2026-09-01', everyThird, '2026-09-05')).toBe(false);
  });

  it('stops after its last day, inclusive', () => {
    const ending = rule({ frequency: 'daily', until: '2026-09-10' });
    expect(isOccurrence('2026-09-01', ending, '2026-09-10')).toBe(true);
    expect(isOccurrence('2026-09-01', ending, '2026-09-11')).toBe(false);
  });
});

describe('weekly', () => {
  // 2026-09-26 is a Saturday; 2026-09-29 a Tuesday.
  it('with no weekdays, lands on the first occurrence’s weekday', () => {
    const weekly = rule({ frequency: 'weekly' });
    expect(isOccurrence('2026-09-26', weekly, '2026-10-03')).toBe(true);
    expect(isOccurrence('2026-09-26', weekly, '2026-10-04')).toBe(false);
  });

  it('on the weekdays it names', () => {
    const tueThu = rule({ frequency: 'weekly', weekdays: [2, 4] });
    expect(isOccurrence('2026-09-28', tueThu, '2026-09-29')).toBe(true);
    expect(isOccurrence('2026-09-28', tueThu, '2026-10-01')).toBe(true);
    expect(isOccurrence('2026-09-28', tueThu, '2026-09-30')).toBe(false);
  });

  it('every second week counts weeks from the first one’s Monday', () => {
    // First on Saturday 26 Sept, whose week starts Monday 21. The week of
    // Monday 28 is skipped; the week of Monday 5 October is the next one.
    const fortnightly = rule({ frequency: 'weekly', interval: 2, weekdays: [2, 6] });
    expect(isOccurrence('2026-09-26', fortnightly, '2026-09-29')).toBe(false);
    expect(isOccurrence('2026-09-26', fortnightly, '2026-10-06')).toBe(true);
    expect(isOccurrence('2026-09-26', fortnightly, '2026-10-10')).toBe(true);
    // The Tuesday of the first week is before the first occurrence.
    expect(isOccurrence('2026-09-26', fortnightly, '2026-09-22')).toBe(false);
  });
});

describe('monthly', () => {
  it('on the same day of the month', () => {
    const monthly = rule({ frequency: 'monthly' });
    expect(isOccurrence('2026-01-15', monthly, '2026-09-15')).toBe(true);
    expect(isOccurrence('2026-01-15', monthly, '2026-09-16')).toBe(false);
  });

  it('skips a month too short for the day rather than moving it', () => {
    const monthly = rule({ frequency: 'monthly' });
    expect(isOccurrence('2026-01-31', monthly, '2026-02-28')).toBe(false);
    expect(isOccurrence('2026-01-31', monthly, '2026-03-31')).toBe(true);
  });

  it('every third month', () => {
    const quarterly = rule({ frequency: 'monthly', interval: 3 });
    expect(isOccurrence('2026-01-10', quarterly, '2026-04-10')).toBe(true);
    expect(isOccurrence('2026-01-10', quarterly, '2026-05-10')).toBe(false);
  });
});

describe('what is not a date or not a rule', () => {
  it('a day that is not in the calendar is never an occurrence', () => {
    expect(isOccurrence('2026-09-01', rule({ frequency: 'daily' }), '2026-02-30')).toBe(false);
    expect(isOccurrence('2026-09-01', rule({ frequency: 'daily' }), 'yesterday')).toBe(false);
  });

  it('a rule this build cannot read happens once, on its first day (BE-10)', () => {
    const unreadable = rule({ frequency: 'daily', interval: 0 });
    expect(isOccurrence('2026-09-01', unreadable, '2026-09-01')).toBe(true);
    expect(isOccurrence('2026-09-01', unreadable, '2026-09-02')).toBe(false);
  });
});
