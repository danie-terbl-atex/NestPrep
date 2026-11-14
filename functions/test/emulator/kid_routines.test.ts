import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { clearFirestore, closeAdmin } from './emulator_harness';
import {
  aFamily,
  aMoment,
  addProfile,
  balanceOf,
  daysAgo,
  expectBalance,
  household,
  read,
  settled,
  status,
  today,
  type Family,
} from './chore_points_fixture';

/**
 * A routine's stars end to end (kid-routines ADR-0001): real writes to a tick
 * wake `awardRoutineStars` in the Functions emulator. After every award and
 * withdrawal the balance is checked against the sum of the ledger.
 */

afterAll(closeAdmin);

let family: Family;

beforeEach(async () => {
  await clearFirestore();
  family = await aFamily();
});

/** A routine as the client writes one: daily from ten days ago, two steps, three stars. */
async function aRoutine(routineId: string, overrides: Record<string, unknown> = {}): Promise<void> {
  const step = (id: string): Record<string, unknown> => ({
    id,
    title: 'Brush your teeth',
    parts: [{ id: `${id}-p1`, text: 'Top and bottom', weekdays: [] }],
  });
  await household(family.householdId)
    .collection('kidRoutines')
    .doc(routineId)
    .set({
      name: 'Morning',
      slot: 'morning',
      kidIds: [family.mia],
      firstDate: daysAgo(10),
      recurrence: { frequency: 'daily', interval: 1, weekdays: [], until: null },
      finishBy: 450,
      points: 3,
      steps: [step('s1'), step('s2')],
      createdBy: family.samMember,
      createdAt: new Date(),
      ...overrides,
    });
}

/** A child's day, keyed the way the client keys one. */
async function tick(
  routineId: string,
  doneStepIds: string[],
  options: { date?: string; kidId?: string } = {},
): Promise<string> {
  const date = options.date ?? today();
  const kidId = options.kidId ?? family.mia;
  const id = `${routineId}_${kidId}_${date}`;
  await household(family.householdId).collection('kidRoutineTicks').doc(id).set({
    routineId,
    kidId,
    occurrenceDate: date,
    doneStepIds,
    updatedBy: kidId,
    updatedAt: new Date(),
  });
  return id;
}

const ALL = ['s1', 's2'];

describe('finishing a routine', () => {
  it('lands its stars once, with an award and a ledger line, and moves the streak', async () => {
    await aRoutine('morning');
    const id = await tick('morning', ALL);

    await expectBalance(family, family.mia, 3);
    expect(await read(family, 'kidRoutineAwards', id)).toMatchObject({
      memberId: family.mia,
      routineId: 'morning',
      occurrenceDate: today(),
      title: 'Morning',
      points: 3,
      status: 'awarded',
      round: 1,
      settledAt: null,
    });
    expect(await read(family, 'pointEntries', `routine_${id}_1`)).toMatchObject({
      memberId: family.mia,
      delta: 3,
      kind: 'routine',
      sourceId: id,
      title: 'Morning',
    });
    expect(await read(family, 'pointBalances', family.mia)).toMatchObject({
      earned: 3,
      spent: 0,
      streakDays: 1,
      streakLastDay: today(),
    });
  });

  it('writing the same tick again pays nothing more', async () => {
    await aRoutine('morning');
    const id = await tick('morning', ALL);
    await expectBalance(family, family.mia, 3);
    await tick('morning', ALL);
    await aMoment();
    await expectBalance(family, family.mia, 3);
    expect(await read(family, 'kidRoutineAwards', id)).toMatchObject({ round: 1 });
  });

  it('unticking one step takes back exactly what was given, and finishing again gives it again', async () => {
    await aRoutine('morning');
    const id = await tick('morning', ALL);
    await expectBalance(family, family.mia, 3);

    await tick('morning', ['s1']);
    await settled(family, 'kidRoutineAwards', id, (value) => status(value) === 'withdrawn');
    await expectBalance(family, family.mia, 0);
    expect(await read(family, 'pointEntries', `routine_undo_${id}_1`)).toMatchObject({
      delta: -3,
      kind: 'routineUndone',
    });

    await tick('morning', ALL);
    await settled(family, 'kidRoutineAwards', id, (value) => value?.['round'] === 2);
    await expectBalance(family, family.mia, 3);
    expect(await read(family, 'pointBalances', family.mia)).toMatchObject({
      earned: 3,
      streakDays: 1,
    });
  });

  it('a tick removed withdraws the stars, and a live award is not re-priced', async () => {
    await aRoutine('morning');
    const id = await tick('morning', ALL);
    await expectBalance(family, family.mia, 3);

    await household(family.householdId).collection('kidRoutines').doc('morning').update({
      points: 10,
    });
    await tick('morning', ['s2', 's1']);
    await aMoment();
    await expectBalance(family, family.mia, 3);

    await household(family.householdId).collection('kidRoutineTicks').doc(id).delete();
    await settled(family, 'kidRoutineAwards', id, (value) => status(value) === 'withdrawn');
    await expectBalance(family, family.mia, 0);
  });

  it('each child a routine names earns for their own day', async () => {
    const leo = await addProfile(family.householdId, 'Leo', 'kid');
    await aRoutine('morning', { kidIds: [family.mia, leo] });
    await tick('morning', ALL);
    await tick('morning', ALL, { kidId: leo });
    await expectBalance(family, family.mia, 3);
    await expectBalance(family, leo, 3);
  });
});

describe('what earns nothing', () => {
  it('a half-done routine, or one worth no stars', async () => {
    await aRoutine('morning');
    await aRoutine('plain', { points: 0 });
    const id = await tick('morning', ['s1']);
    await tick('plain', ALL);
    await aMoment();
    expect(await balanceOf(family, family.mia)).toBeUndefined();
    expect(await read(family, 'kidRoutineAwards', id)).toBeUndefined();
  });

  it('a day that is not the routine’s, tomorrow, or more than a week back', async () => {
    await aRoutine('weekly', {
      firstDate: daysAgo(14),
      recurrence: { frequency: 'weekly', interval: 1, weekdays: [], until: null },
    });
    await aRoutine('morning');
    await tick('weekly', ALL, { date: daysAgo(1) });
    await tick('morning', ALL, { date: daysAgo(-1) });
    await tick('morning', ALL, { date: daysAgo(8) });
    await aMoment();
    expect(await balanceOf(family, family.mia)).toBeUndefined();
  });

  it('a profile that is not a kid, a kid the routine does not name, a routine that is gone', async () => {
    const leo = await addProfile(family.householdId, 'Leo', 'kid');
    await aRoutine('morning', { kidIds: [family.mia, family.samMember] });
    await tick('morning', ALL, { kidId: family.samMember });
    await tick('morning', ALL, { kidId: leo });
    await tick('gone', ALL);
    await aMoment();
    expect(await balanceOf(family, family.samMember)).toBeUndefined();
    expect(await balanceOf(family, leo)).toBeUndefined();
    expect(await balanceOf(family, family.mia)).toBeUndefined();
  });
});
