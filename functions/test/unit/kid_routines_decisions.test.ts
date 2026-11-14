import { describe, expect, it } from 'vitest';

import { applyLine } from '../../src/chore_points/point_ledger';
import { NO_STREAK } from '../../src/chore_points/streak';
import type { StoredKidRoutine } from '../../src/kid_routines/routine_documents';
import { storedKidRoutine } from '../../src/kid_routines/routine_documents';
import { decideAward, type AwardFacts } from '../../src/kid_routines/routine_eligibility';

/**
 * Whether a child's day of a routine earns its stars (kid-routines ADR-0001):
 * every reason it does not, each a way a child's own device could otherwise
 * mint them.
 */

const TODAY = '2026-09-29';

const routine = (overrides: Partial<StoredKidRoutine> = {}): StoredKidRoutine => ({
  name: 'Morning',
  kidIds: ['m-mia', 'm-leo'],
  firstDate: '2026-09-01',
  recurrence: { frequency: 'daily', interval: 1, weekdays: [], until: null },
  points: 3,
  steps: [{ id: 's1' }, { id: 's2' }],
  ...overrides,
});

const facts = (
  overrides: Partial<AwardFacts> = {},
  tick: Partial<AwardFacts['tick']> = {},
): AwardFacts => ({
  tick: {
    routineId: 'r-morning',
    kidId: 'm-mia',
    occurrenceDate: TODAY,
    doneStepIds: ['s1', 's2'],
    ...tick,
  },
  routine: routine(),
  kidRole: 'kid',
  today: TODAY,
  ...overrides,
});

describe('whether a routine’s day earns stars', () => {
  it('a kid with every step done today earns the routine’s stars, under its name', () => {
    expect(decideAward(facts())).toEqual({
      memberId: 'm-mia',
      routineId: 'r-morning',
      occurrenceDate: TODAY,
      title: 'Morning',
      points: 3,
    });
  });

  it('done ids the routine no longer has do not get in the way', () => {
    expect(decideAward(facts({}, { doneStepIds: ['gone', 's2', 's1'] }))).toMatchObject({
      points: 3,
    });
  });

  it('a routine that is gone, or worth nothing, earns nothing', () => {
    expect(decideAward(facts({ routine: undefined }))).toBe('noRoutine');
    expect(decideAward(facts({ routine: routine({ points: 0 }) }))).toBe('noStars');
  });

  it('a child the routine does not name, or a profile that is not a kid', () => {
    expect(decideAward(facts({}, { kidId: 'm-ava' }))).toBe('notNamed');
    expect(decideAward(facts({ kidRole: 'parent' }))).toBe('notAKid');
    expect(decideAward(facts({ kidRole: undefined }))).toBe('notAKid');
  });

  it('tomorrow, and more than a week back', () => {
    expect(decideAward(facts({}, { occurrenceDate: '2026-09-30' }))).toBe('inTheFuture');
    expect(decideAward(facts({}, { occurrenceDate: '2026-09-21' }))).toBe('tooLongAgo');
    expect(decideAward(facts({}, { occurrenceDate: '2026-09-22' }))).toMatchObject({ points: 3 });
  });

  it('a day the routine does not happen on', () => {
    const weekdays = routine({
      recurrence: { frequency: 'weekly', interval: 1, weekdays: [1, 2, 3, 4, 5], until: null },
    });
    expect(decideAward(facts({ routine: weekdays }, { occurrenceDate: '2026-09-27' }))).toBe(
      'notAnOccurrence',
    );
    expect(decideAward(facts({ routine: routine({ recurrence: null }) }))).toBe('notAnOccurrence');
  });

  it('a step still to do, or a routine with no steps at all', () => {
    expect(decideAward(facts({}, { doneStepIds: ['s1'] }))).toBe('notFinished');
    expect(decideAward(facts({}, { doneStepIds: [] }))).toBe('notFinished');
    expect(decideAward(facts({ routine: routine({ steps: [] }) }))).toBe('notFinished');
  });
});

describe('a routine as the client stores it', () => {
  it('is read past the keys the award does not need', () => {
    const parsed = storedKidRoutine.safeParse({
      name: 'Morning',
      slot: 'morning',
      kidIds: ['m-mia'],
      firstDate: '2026-09-01',
      recurrence: null,
      finishBy: 450,
      points: 3,
      steps: [{ id: 's1', title: 'Brush teeth', parts: [{ id: 'p1', text: 'Top', weekdays: [] }] }],
      createdBy: 'm-sam',
    });
    expect(parsed.success && parsed.data.steps).toEqual([{ id: 's1' }]);
  });

  it('does not parse with stars past twenty or a step with no id', () => {
    const base = { name: 'Morning', kidIds: ['m-mia'], firstDate: '2026-09-01', steps: [] };
    expect(storedKidRoutine.safeParse({ ...base, points: 21 }).success).toBe(false);
    expect(storedKidRoutine.safeParse({ ...base, steps: [{ title: 'x' }] }).success).toBe(false);
  });
});

describe('a routine’s line on the ledger', () => {
  const empty = { balance: 0, earned: 0, spent: 0, ...NO_STREAK };
  const line = { entryId: 'e', memberId: 'm-mia', delta: 3, sourceId: 't', title: 'Morning' };

  it('is earned like a chore’s, and undone takes back exactly that', () => {
    const after = applyLine(empty, { ...line, kind: 'routine', earnedOn: TODAY });
    expect(after).toMatchObject({ balance: 3, earned: 3, spent: 0, streakDays: 1 });
    expect(applyLine(after, { ...line, delta: -3, kind: 'routineUndone' })).toMatchObject({
      balance: 0,
      earned: 0,
      spent: 0,
      streakDays: 1,
    });
  });
});
