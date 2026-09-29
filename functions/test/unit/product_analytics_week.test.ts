import { describe, expect, it } from 'vitest';

import {
  LAUNCH_TIME_ZONE,
  countingZoneFor,
  isKnownTimeZone,
  mondayOf,
  shiftWeek,
  weekKeyOf,
  weekStartDate,
} from '../../src/product_analytics/iso_week';

/**
 * The week every beta number is counted in (product-analytics ADR-0001): ISO
 * weeks, in the household's own timezone. A week that is wrong at a boundary
 * moves a family from one week's count to the next, and nothing else notices.
 */
describe('the week an instant falls in', () => {
  it('is the ISO week, Monday first', () => {
    expect(weekKeyOf(new Date('2026-09-28T10:00:00Z'), 'UTC')).toBe('2026-W40');
    expect(weekKeyOf(new Date('2026-10-04T10:00:00Z'), 'UTC')).toBe('2026-W40');
    expect(weekKeyOf(new Date('2026-10-05T10:00:00Z'), 'UTC')).toBe('2026-W41');
  });

  it('is the household"s own week, not the server"s', () => {
    // 00:30 on Monday in Johannesburg is still Sunday in UTC.
    const mondayJustAfterMidnight = new Date('2026-09-27T22:30:00Z');
    expect(weekKeyOf(mondayJustAfterMidnight, 'Africa/Johannesburg')).toBe('2026-W40');
    expect(weekKeyOf(mondayJustAfterMidnight, 'UTC')).toBe('2026-W39');
  });

  it('takes its year from the week"s Thursday at both ends of a year', () => {
    expect(weekKeyOf(new Date('2027-01-01T12:00:00Z'), 'UTC')).toBe('2026-W53');
    expect(weekKeyOf(new Date('2021-01-03T12:00:00Z'), 'UTC')).toBe('2020-W53');
    expect(weekKeyOf(new Date('2024-12-30T12:00:00Z'), 'UTC')).toBe('2025-W01');
  });
});

describe('a week key', () => {
  it('starts on its Monday', () => {
    expect(weekStartDate('2026-W40')).toBe('2026-09-28');
    expect(weekStartDate('2026-W53')).toBe('2026-12-28');
    expect(weekStartDate('2025-W01')).toBe('2024-12-30');
    expect(mondayOf('2026-W01').getUTCDay()).toBe(1);
  });

  it('shifts across a year boundary in both directions', () => {
    expect(shiftWeek('2026-W53', 1)).toBe('2027-W01');
    expect(shiftWeek('2027-W01', -1)).toBe('2026-W53');
    expect(shiftWeek('2026-W40', -2)).toBe('2026-W38');
  });

  it('refuses something that is not one', () => {
    expect(() => mondayOf('2026-40')).toThrow(RangeError);
  });

  it('sorts as text in the order of time, which the cohort check relies on', () => {
    const weeks = ['2027-W01', '2026-W09', '2026-W53', '2026-W10'];
    expect([...weeks].sort()).toEqual(['2026-W09', '2026-W10', '2026-W53', '2027-W01']);
  });
});

describe('the zone a household is counted in', () => {
  it('is its own when the runtime knows it', () => {
    expect(isKnownTimeZone('Europe/London')).toBe(true);
    expect(countingZoneFor('Europe/London')).toBe('Europe/London');
  });

  it('is the launch zone when its own cannot be read, rather than no count at all', () => {
    expect(isKnownTimeZone('Mars/Olympus_Mons')).toBe(false);
    expect(countingZoneFor('Mars/Olympus_Mons')).toBe(LAUNCH_TIME_ZONE);
    expect(countingZoneFor(undefined)).toBe(LAUNCH_TIME_ZONE);
  });
});
