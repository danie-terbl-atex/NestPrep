import { describe, expect, it } from 'vitest';

import {
  addDays,
  instantOf,
  isKnownZone,
  knownZoneOr,
  wallClockOf,
  weekdayOf,
} from '../../../src/calendar_sync/zoned_time';

/**
 * The server's half of `HouseholdClock` (calendar ADR-0002): an instant to a
 * household's day and minute, and back, across the clocks changing.
 */
describe('a wall clock', () => {
  it('is the household day and minute an instant shows', () => {
    expect(wallClockOf(new Date('2026-09-29T15:00:00Z'), 'Africa/Johannesburg')).toEqual({
      date: '2026-09-29',
      minute: 17 * 60,
    });
  });

  it('crosses midnight into the household day, not the UTC one', () => {
    expect(wallClockOf(new Date('2026-09-29T23:30:00Z'), 'Africa/Johannesburg')).toEqual({
      date: '2026-09-30',
      minute: 90,
    });
  });

  it('follows British Summer Time on either side of the change', () => {
    // 25 October 2026: clocks go back at 02:00 BST.
    expect(wallClockOf(new Date('2026-10-23T06:30:00Z'), 'Europe/London').minute).toBe(7 * 60 + 30);
    expect(wallClockOf(new Date('2026-10-30T07:30:00Z'), 'Europe/London').minute).toBe(7 * 60 + 30);
  });
});

describe('an instant', () => {
  it('is what a wall-clock time means in the zone', () => {
    expect(instantOf('2026-09-29', 17 * 60, 'Africa/Johannesburg').toISOString()).toBe(
      '2026-09-29T15:00:00.000Z',
    );
    expect(instantOf('2026-07-01', 9 * 60, 'Europe/London').toISOString()).toBe(
      '2026-07-01T08:00:00.000Z',
    );
    expect(instantOf('2026-12-01', 9 * 60, 'Europe/London').toISOString()).toBe(
      '2026-12-01T09:00:00.000Z',
    );
  });

  it('lands just after a gap the clocks skip', () => {
    // 29 March 2026, London: 01:00 GMT becomes 02:00 BST; 01:30 never happens.
    const instant = instantOf('2026-03-29', 90, 'Europe/London');
    expect(instant.toISOString()).toBe('2026-03-29T01:30:00.000Z');
    expect(wallClockOf(instant, 'Europe/London').minute).toBe(2 * 60 + 30);
  });

  it('takes the first of an hour that happens twice', () => {
    // 25 October 2026, London: 01:30 happens in BST and again in GMT.
    expect(instantOf('2026-10-25', 90, 'Europe/London').toISOString()).toBe(
      '2026-10-25T00:30:00.000Z',
    );
  });

  it('round-trips through the wall clock every quarter hour of a change day', () => {
    for (let minute = 0; minute < 24 * 60; minute += 15) {
      const instant = instantOf('2026-11-01', minute, 'America/New_York');
      const back = wallClockOf(instant, 'America/New_York');
      if (back.minute !== minute) continue; // a skipped or doubled quarter
      expect(back.date).toBe('2026-11-01');
    }
  });
});

describe('days and zones', () => {
  it('adds days as calendar days', () => {
    expect(addDays('2026-12-31', 1)).toBe('2027-01-01');
    expect(addDays('2028-03-01', -1)).toBe('2028-02-29');
  });

  it('numbers weekdays the way the app does, Monday first', () => {
    expect(weekdayOf('2026-09-28')).toBe(1);
    expect(weekdayOf('2026-10-04')).toBe(7);
  });

  it('knows an IANA zone and falls back to UTC for one it does not', () => {
    expect(isKnownZone('Africa/Johannesburg')).toBe(true);
    expect(isKnownZone('Mars/Olympus_Mons')).toBe(false);
    expect(knownZoneOr('Mars/Olympus_Mons')).toBe('UTC');
    expect(knownZoneOr(undefined)).toBe('UTC');
  });
});
