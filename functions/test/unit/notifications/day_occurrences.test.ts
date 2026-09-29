import { describe, expect, it } from 'vitest';

import type { StoredTask } from '../../../src/chore_points/point_documents';
import {
  choresOn,
  eventsOn,
  type HouseholdEventRecord,
} from '../../../src/notifications/day_occurrences';
import { kitFor } from '../../../src/notifications/kit_vocabulary';
import { everyDay, weeklyOn } from '../../recurrence_shape';

/** What happens today, from what is stored (notifications ADR-0002). */

const TUESDAY = '2026-09-29';

function event(
  id: string,
  date: string,
  recurrence: ReturnType<typeof weeklyOn> | null = null,
): HouseholdEventRecord {
  return {
    id,
    event: { title: id, date, startMinute: 9 * 60, endMinute: null, recurrence },
    memberIds: [],
  };
}

describe('today’s events', () => {
  it('a once-off on today, a weekly on Tuesdays, and not a weekly on Wednesdays', () => {
    const events = eventsOn(
      TUESDAY,
      [
        event('once', TUESDAY),
        event('tuesdays', '2026-09-01', weeklyOn([2])),
        event('wednesdays', '2026-09-02', weeklyOn([3])),
        event('yesterday', '2026-09-28'),
      ],
      new Set(),
      [],
    );
    expect(events.map((found) => found.title)).toEqual(['once', 'tuesdays']);
  });

  it('a skipped occurrence is not on today', () => {
    const events = eventsOn(
      TUESDAY,
      [event('daily', '2026-09-01', everyDay())],
      new Set(['daily']),
      [],
    );
    expect(events).toEqual([]);
  });

  it('an imported event spanning today is there all day from its second day', () => {
    const synced = [
      {
        title: 'Camp',
        date: '2026-09-28',
        endDate: '2026-09-30',
        startMinute: 600,
        memberId: 'm-leo',
      },
      {
        title: 'Over',
        date: '2026-09-20',
        endDate: '2026-09-21',
        startMinute: null,
        memberId: 'm-leo',
      },
    ];
    expect(eventsOn(TUESDAY, [], new Set(), synced)).toEqual([
      { title: 'Camp', startMinute: null, memberIds: ['m-leo'] },
    ]);
  });
});

describe('today’s chores', () => {
  const task = (routineId: string | null, assigneeIds: string[] = []): StoredTask => ({
    title: 'Laundry',
    dueDate: '2026-09-01',
    recurrence: weeklyOn([2]),
    assigneeIds,
    routineId,
    points: 0,
    needsApproval: false,
  });

  it('a chore on today by its own schedule, not yet ticked', () => {
    expect(choresOn(TUESDAY, [{ id: 't1', task: task(null) }], {}, new Set())).toHaveLength(1);
    expect(choresOn(TUESDAY, [{ id: 't1', task: task(null) }], {}, new Set(['t1']))).toEqual([]);
  });

  it('a routine’s schedule and default people win over the task’s own', () => {
    const routines = {
      saturday: {
        firstDate: '2026-09-05',
        recurrence: weeklyOn([6]),
        defaultAssigneeIds: ['m-pat'],
      },
      tuesday: {
        firstDate: '2026-09-01',
        recurrence: weeklyOn([2]),
        defaultAssigneeIds: ['m-pat'],
      },
    };
    expect(choresOn(TUESDAY, [{ id: 't1', task: task('saturday') }], routines, new Set())).toEqual(
      [],
    );
    expect(choresOn(TUESDAY, [{ id: 't2', task: task('tuesday') }], routines, new Set())).toEqual([
      { title: 'Laundry', assigneeIds: ['m-pat'] },
    ]);
  });
});

describe('what an event means somebody packs', () => {
  it.each([
    ['Swimming lesson', 'Swimming kit'],
    ['Soccer practice', 'Soccer kit'],
    ['PE', 'Sports kit'],
    ['Library day', 'Library books'],
    ['Piano', 'Instrument and music'],
  ])('%s → %s', (title, kit) => {
    expect(kitFor(title)).toBe(kit);
  });

  it('only whole words, so "Peter’s party" packs nothing', () => {
    expect(kitFor('Peter’s party')).toBeNull();
    expect(kitFor('Dentist')).toBeNull();
  });
});
