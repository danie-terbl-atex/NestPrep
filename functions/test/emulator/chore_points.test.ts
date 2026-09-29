import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { callAs, clearFirestore, closeAdmin, signUp } from './emulator_harness';
import { expectRefusal } from './product_analytics_fixture';
import {
  aChore,
  aFamily,
  aKidDevice,
  aMember,
  aMoment,
  balanceOf,
  completionId,
  daysAgo,
  household,
  expectBalance,
  read,
  status,
  settled,
  tick,
  today,
  untick,
  type Family,
} from './chore_points_fixture';

/**
 * A child's stars end to end (todos ADR-0003): real writes wake the real
 * triggers in the Functions emulator, and a parent's review goes over HTTP
 * with a real token. After every test the balance is checked against the sum
 * of the ledger it is a projection of.
 */

afterAll(closeAdmin);

let family: Family;

beforeEach(async () => {
  await clearFirestore();
  family = await aFamily();
});

describe('ticking a starred chore', () => {
  it('lands its stars at once, with a claim and a ledger line', async () => {
    await aChore(family, 'bed');
    const id = await tick(family, 'bed');

    await expectBalance(family, family.mia, 5);
    const claim = await read(family, 'pointClaims', id);
    expect(claim).toMatchObject({ memberId: family.mia, points: 5, status: 'awarded', round: 1 });
    const balance = await read(family, 'pointBalances', family.mia);
    expect(balance).toMatchObject({ earned: 5, spent: 0, streakDays: 1, streakLastDay: today() });
  });

  it('an untick takes back exactly what the tick gave, and a re-tick gives it again', async () => {
    await aChore(family, 'bed');
    const id = await tick(family, 'bed');
    await expectBalance(family, family.mia, 5);

    await untick(family, id);
    await settled(family, 'pointClaims', id, (value) => status(value) === 'withdrawn');
    await expectBalance(family, family.mia, 0);

    await tick(family, 'bed');
    await settled(family, 'pointClaims', id, (value) => value?.['round'] === 2);
    await expectBalance(family, family.mia, 5);
  });

  it('writing the same tick again pays nothing more', async () => {
    await aChore(family, 'bed');
    await tick(family, 'bed');
    await expectBalance(family, family.mia, 5);
    await tick(family, 'bed');
    await aMoment();
    await expectBalance(family, family.mia, 5);
  });

  it('a parent ticking it for an unclaimed child still credits the child', async () => {
    await aChore(family, 'bed', { needsApproval: true });
    const id = await tick(family, 'bed', { by: family.samMember });
    await settled(family, 'pointClaims', id, (value) => status(value) === 'awarded');
    await expectBalance(family, family.mia, 5);
  });
});

describe('what earns nothing', () => {
  it('a day that is not the chore’s, tomorrow, or more than a week back', async () => {
    await aChore(family, 'saturdays', {
      dueDate: daysAgo(14),
      recurrence: { frequency: 'weekly', interval: 1, weekdays: [], until: null },
    });
    await aChore(family, 'bed');
    // Fourteen days ago was the weekly chore's day; one day ago was not.
    await tick(family, 'saturdays', { date: daysAgo(1) });
    await tick(family, 'bed', { date: daysAgo(8) });
    await tick(family, 'bed', { date: daysAgo(-1) });
    await aMoment();
    expect(await balanceOf(family, family.mia)).toBeUndefined();
  });

  it('a chore with no stars, or one ticked for a parent', async () => {
    await aChore(family, 'plain', { points: 0 });
    await aChore(family, 'parents', { assigneeIds: [family.samMember] });
    await tick(family, 'plain');
    await tick(family, 'parents', { by: family.samMember, forMember: family.samMember });
    await aMoment();
    expect(await balanceOf(family, family.mia)).toBeUndefined();
    expect(await balanceOf(family, family.samMember)).toBeUndefined();
  });
});

describe('a chore a parent checks first', () => {
  it('waits, then lands when a parent says it looks good — once', async () => {
    await aChore(family, 'room', { needsApproval: true, points: 10 });
    const id = await tick(family, 'room');
    await settled(family, 'pointClaims', id, (value) => status(value) === 'pending');
    expect(await balanceOf(family, family.mia)).toBeUndefined();

    const result = await callAs<{ status: string }>(family.sam, 'reviewChore', {
      householdId: family.householdId,
      completionId: id,
      decision: 'approve',
    });
    expect(result.status).toBe('awarded');
    await expectBalance(family, family.mia, 10);
    expect(await read(family, 'pointClaims', id)).toMatchObject({ settledBy: family.samMember });

    await expectRefusal(
      callAs(family.sam, 'reviewChore', {
        householdId: family.householdId,
        completionId: id,
        decision: 'approve',
      }),
      'alreadySettled',
    );
    await expectBalance(family, family.mia, 10);
  });

  it('sent back, the chore is undone again and nothing is paid', async () => {
    await aChore(family, 'room', { needsApproval: true });
    const id = await tick(family, 'room');
    await settled(family, 'pointClaims', id, (value) => status(value) === 'pending');

    await callAs(family.sam, 'reviewChore', {
      householdId: family.householdId,
      completionId: id,
      decision: 'sendBack',
    });

    const completion = await household(family.householdId)
      .collection('taskCompletions')
      .doc(id)
      .get();
    expect(completion.exists).toBe(false);
    await aMoment();
    expect(status(await read(family, 'pointClaims', id))).toBe('sentBack');
    expect(await balanceOf(family, family.mia)).toBeUndefined();
  });

  it('only family may review, and a kid device may call nothing', async () => {
    await aChore(family, 'room', { needsApproval: true });
    const id = await tick(family, 'room');
    await settled(family, 'pointClaims', id, (value) => status(value) === 'pending');
    const body = { householdId: family.householdId, completionId: id, decision: 'approve' };

    await expectRefusal(
      callAs(await aKidDevice(family, family.mia), 'reviewChore', body),
      'kidAccount',
    );
    await expectRefusal(callAs(await aMember(family, 'helper'), 'reviewChore', body), 'notFamily');
    await expectRefusal(callAs(await aMember(family, 'kid'), 'reviewChore', body), 'notFamily');
    await expectRefusal(callAs(await signUp(), 'reviewChore', body), 'notAMember');
    await expectRefusal(
      callAs(family.sam, 'reviewChore', { ...body, completionId: completionId('nope', today()) }),
      'claimNotFound',
    );
    expect(status(await read(family, 'pointClaims', id))).toBe('pending');
  });
});
