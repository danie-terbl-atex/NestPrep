import { describe, expect, it } from 'vitest';

import { FRAME_REFUSALS } from '../../../src/frames/frame_errors';
import { assembleFrameMonth, monthGrid, monthInReach } from '../../../src/frames/frame_month';
import { FRAME_MONTH_PER_CREDENTIAL } from '../../../src/frames/frame_policy';
import { getFrameMonthInput } from '../../../src/frames/frame_schemas';
import { parseInput } from '../../../src/household/parse_input';
import { HttpsError } from 'firebase-functions/v2/https';
import { weeklyOn } from '../../recurrence_shape';

/** A month of a frame's calendar (photo-frames ADR-0005). */

const SECRET = 'a'.repeat(43);
const NAMES = { 'm-mia': 'Mia Parker', 'm-sam': 'Sam' };

describe('the grid a month covers', () => {
  it('runs Monday to Sunday over whole weeks', () => {
    expect(monthGrid('2026-10')).toEqual({ from: '2026-09-28', to: '2026-11-01' });
    expect(monthGrid('2026-02')).toEqual({ from: '2026-01-26', to: '2026-03-01' });
    expect(monthGrid('2027-02')).toEqual({ from: '2027-02-01', to: '2027-02-28' });
    expect(monthGrid('2026-08')).toEqual({ from: '2026-07-27', to: '2026-09-06' });
  });

  it('reaches twelve months either side of today, across years', () => {
    expect(monthInReach('2026-10', '2026-10-25')).toBe(true);
    expect(monthInReach('2027-10', '2026-10-25')).toBe(true);
    expect(monthInReach('2025-10', '2026-10-25')).toBe(true);
    expect(monthInReach('2027-11', '2026-10-25')).toBe(false);
    expect(monthInReach('2025-09', '2026-10-25')).toBe(false);
  });
});

describe('a frame’s month', () => {
  it('every day of the grid, with the day’s own events and people by first name', () => {
    const month = assembleFrameMonth({
      today: '2026-10-25',
      month: '2026-10',
      names: NAMES,
      events: {
        own: [
          {
            id: 'swim',
            event: {
              title: 'Swimming',
              date: '2026-09-01',
              startMinute: 900,
              endMinute: 960,
              recurrence: weeklyOn([3]),
            },
            memberIds: ['m-mia', 'm-gone'],
            note: ' Goggles ',
          },
        ],
        skips: [{ eventId: 'swim', occurrenceDate: '2026-10-14' }],
        synced: [
          {
            title: 'Half term',
            date: '2026-10-30',
            endDate: '2026-11-01',
            startMinute: null,
            endMinute: null,
            memberId: 'm-sam',
          },
        ],
      },
    });

    expect(month).toMatchObject({ status: 'linked', today: '2026-10-25', month: '2026-10' });
    expect(month.days).toHaveLength(35);
    expect(month.days[0]?.date).toBe('2026-09-28');
    expect(month.days.at(-1)?.date).toBe('2026-11-01');
    const swims = month.days.filter((day) =>
      day.events.some((event) => event.title === 'Swimming'),
    );
    expect(swims.map((day) => day.date)).toEqual([
      '2026-09-30',
      '2026-10-07',
      '2026-10-21',
      '2026-10-28',
    ]);
    expect(swims[0]?.events[0]).toEqual({
      title: 'Swimming',
      allDay: false,
      start: '15:00',
      end: '16:00',
      who: ['Mia'],
      note: 'Goggles',
      repeats: true,
    });
    const halfTerm = month.days.filter((day) =>
      day.events.some((event) => event.title === 'Half term'),
    );
    expect(halfTerm.map((day) => day.date)).toEqual(['2026-10-30', '2026-10-31', '2026-11-01']);
  });

  it('has no days when the frame’s calendar is off', () => {
    expect(assembleFrameMonth({ today: '2026-10-25', month: '2026-10', names: NAMES })).toEqual({
      status: 'linked',
      today: '2026-10-25',
      month: '2026-10',
      days: [],
    });
  });
});

describe('getFrameMonth’s input and limits', () => {
  it('takes a secret and a YYYY-MM month, nothing looser', () => {
    expect(parseInput(getFrameMonthInput, { secret: SECRET, month: '2026-10' })).toEqual({
      secret: SECRET,
      month: '2026-10',
    });
    for (const month of ['2026-13', '2026-1', '26-10', '2026-10-01', '', null]) {
      expect(() => parseInput(getFrameMonthInput, { secret: SECRET, month })).toThrow(HttpsError);
    }
    expect(() => parseInput(getFrameMonthInput, { month: '2026-10' })).toThrow(HttpsError);
  });

  it('refuses a far month by its own reason, and is limited per credential', () => {
    expect(FRAME_REFUSALS.monthOutOfRange[0]).toBe('out-of-range');
    expect(FRAME_MONTH_PER_CREDENTIAL).toMatchObject({
      name: 'getFrameMonth:credential',
      limit: 120,
    });
  });
});
