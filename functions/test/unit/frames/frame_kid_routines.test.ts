import { describe, expect, it } from 'vitest';

import { assembleFrameDay, clockTime } from '../../../src/frames/frame_day';
import {
  type FrameKidRoutine,
  type FrameKidRoutineRecord,
  frameKidRoutineShape,
  kidRoutinesPanel,
} from '../../../src/frames/frame_kid_routines';

/** Children's routines on a frame (C-0023 rev 21, photo-frames ADR-0021). */

const WEDNESDAY = '2026-11-04';
const KIDS = { 'm-mia': 'Mia', 'm-leo': 'Leo' };

function routine(over: Record<string, unknown> = {}): FrameKidRoutineRecord {
  return {
    id: 'morning',
    ...frameKidRoutineShape.parse({
      name: 'Morning',
      slot: 'morning',
      kidIds: ['m-mia', 'm-leo'],
      firstDate: '2026-11-02',
      recurrence: { frequency: 'weekly', interval: 1, weekdays: [1, 2, 3, 4, 5], until: null },
      finishBy: 435,
      points: 3,
      steps: [
        { id: 's1', title: 'Get dressed', picture: 'get-dressed', parts: [] },
        {
          id: 's2',
          title: 'Pack school bag',
          picture: 'pack-school-bag',
          note: 'Check the diary',
          parts: [
            { id: 'p1', text: 'Lunchbox', picture: 'pack-lunchbox', weekdays: [] },
            { id: 'p2', text: 'Swimming kit', weekdays: [3] },
            { id: 'p3', text: 'Library book', weekdays: [5] },
          ],
        },
      ],
      ...over,
    }),
  };
}

const panel = (
  routines: FrameKidRoutineRecord[],
  done: Record<string, string[]> = {},
  today = WEDNESDAY,
): FrameKidRoutine[] => kidRoutinesPanel({ routines, done }, today, KIDS, clockTime);

describe('a frame’s routines', () => {
  it('one entry per child, by first name, with the steps, today’s things and the time', () => {
    expect(panel([routine()], { 'morning_m-mia': ['s1'] })).toEqual([
      {
        id: 'morning',
        name: 'Morning',
        slot: 'morning',
        who: 'Leo',
        date: WEDNESDAY,
        done: false,
        stars: 3,
        finishBy: '07:15',
        steps: [
          { id: 's1', title: 'Get dressed', done: false, picture: 'get-dressed' },
          {
            id: 's2',
            title: 'Pack school bag',
            done: false,
            picture: 'pack-school-bag',
            note: 'Check the diary',
            parts: [{ text: 'Lunchbox', picture: 'pack-lunchbox' }, { text: 'Swimming kit' }],
          },
        ],
      },
      expect.objectContaining({
        who: 'Mia',
        done: false,
        steps: [
          expect.objectContaining({ id: 's1', done: true }),
          expect.objectContaining({ id: 's2', done: false }),
        ],
      }),
    ]);
  });

  it('is done when every step it still has is ticked, whatever else the tick names', () => {
    const [leo] = panel([routine({ kidIds: ['m-leo'] })], {
      'morning_m-leo': ['s2', 'gone', 's1'],
    });
    expect(leo?.done).toBe(true);
  });

  it('leaves out a day it does not fall on, a child the household does not have, and no steps', () => {
    expect(panel([routine()], {}, '2026-11-07')).toEqual([]);
    expect(panel([routine({ kidIds: ['m-gone'] })])).toEqual([]);
    expect(panel([routine({ steps: [] })])).toEqual([]);
  });

  it('carries no stars or time when there are none', () => {
    const [first] = panel([routine({ points: 0, finishBy: null })]);
    expect(first).not.toHaveProperty('stars');
    expect(first).not.toHaveProperty('finishBy');
  });

  it('runs in the order of a day, then by child', () => {
    const order = panel([
      { ...routine({ slot: 'bedtime', name: 'Bed' }), id: 'bed' },
      routine(),
    ]).map((each) => `${each.slot} ${each.who}`);
    expect(order).toEqual(['morning Leo', 'morning Mia', 'bedtime Leo', 'bedtime Mia']);
  });

  it('reads a routine whose slot or stars it cannot, and refuses one with no step titles', () => {
    expect(routine({ slot: 'teatime', points: 99, finishBy: 'soon' })).toMatchObject({
      slot: 'morning',
      points: 0,
      finishBy: null,
    });
    expect(frameKidRoutineShape.safeParse({ ...routine(), steps: [{ id: 's1' }] }).success).toBe(
      false,
    );
  });
});

describe('the day carries routines', () => {
  const base = {
    householdName: 'Home',
    frameName: 'Kitchen',
    screensaver: null,
    today: WEDNESDAY,
    localMinute: 400,
    names: { 'm-mia': 'Mia Parker', 'm-sam': 'Sam' },
    colors: {},
    kids: ['m-mia'],
    kidRoutines: { routines: [routine({ kidIds: ['m-mia', 'm-sam'] })], done: {} },
  };
  const panels = { calendar: false, todos: true, meals: false, helperMemberId: null };

  it('beside the chores, for kids only, by first name', () => {
    const day = assembleFrameDay({ ...base, panels: panels as never });
    expect(day.routines?.map((each) => each.who)).toEqual(['Mia']);
  });

  it('not at all with chores off, or while the switch is off', () => {
    expect(
      assembleFrameDay({ ...base, panels: { ...panels, todos: false } as never }),
    ).not.toHaveProperty('routines');
    expect(
      assembleFrameDay({ ...base, kidRoutines: undefined, panels: panels as never }),
    ).not.toHaveProperty('routines');
  });
});
