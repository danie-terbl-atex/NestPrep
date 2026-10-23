import { describe, expect, it } from 'vitest';

import { HOUSEHOLD_TIME_ZONE, nextWeekIn } from '../../emulator/household_week';

/**
 * The emulator tests plan "next week" on the household's clock, as the
 * callables do (`openPlanning`): at 01:00 on a South African Monday it is
 * still Sunday in UTC, and a UTC "next week" is the household's this week.
 */
describe('the week after the household’s current one', () => {
  it('is read on the household’s clock, not UTC’s', () => {
    // Monday 12 October 2026, 01:00 in Johannesburg (ISO week 42).
    expect(nextWeekIn(HOUSEHOLD_TIME_ZONE, new Date('2026-10-11T23:00:00Z'))).toBe('2026-W43');
  });

  it('is the same on a weekday afternoon', () => {
    expect(nextWeekIn(HOUSEHOLD_TIME_ZONE, new Date('2026-10-14T12:00:00Z'))).toBe('2026-W43');
  });
});
