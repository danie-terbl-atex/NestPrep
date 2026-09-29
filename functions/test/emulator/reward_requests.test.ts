import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { callAs, clearFirestore, closeAdmin } from './emulator_harness';
import { expectRefusal } from './product_analytics_fixture';
import {
  aChore,
  aFamily,
  aKidDevice,
  aMember,
  addProfile,
  expectBalance,
  household,
  settled,
  status,
  tick,
  type Family,
} from './chore_points_fixture';

/**
 * Spending stars end to end (todos ADR-0003): a request written the way the
 * app writes one wakes `reserveRewardPoints`, which takes the stars in the
 * same transaction as the check; a parent's `settleReward` hands it over or
 * gives them back. The balance is checked against the ledger every time.
 */

afterAll(closeAdmin);

let family: Family;

beforeEach(async () => {
  await clearFirestore();
  family = await aFamily();
});

describe('spending stars', () => {
  async function aReward(id: string, cost: number): Promise<void> {
    await household(family.householdId).collection('rewards').doc(id).set({
      title: 'Ice cream',
      cost,
      icon: 'iceCream',
      createdBy: family.samMember,
      createdAt: new Date(),
    });
  }

  async function ask(requestId: string, rewardId: string, requestedBy = family.mia): Promise<void> {
    await household(family.householdId).collection('rewardRequests').doc(requestId).set({
      rewardId,
      memberId: family.mia,
      requestedBy,
      requestedAt: new Date(),
    });
  }

  beforeEach(async () => {
    await aChore(family, 'bed');
    await tick(family, 'bed');
    await expectBalance(family, family.mia, 5);
    await aReward('ice-cream', 3);
  });

  it('takes the stars when a child asks, and refuses what they cannot afford', async () => {
    await ask('first', 'ice-cream');
    const first = await settled(
      family,
      'rewardRequests',
      'first',
      (value) => status(value) !== undefined,
    );
    expect(first).toMatchObject({ status: 'waiting', cost: 3, title: 'Ice cream' });
    await expectBalance(family, family.mia, 2);

    await ask('second', 'ice-cream');
    const second = await settled(
      family,
      'rewardRequests',
      'second',
      (value) => status(value) !== undefined,
    );
    expect(second).toMatchObject({ status: 'refused', refusal: 'notEnoughPoints' });
    await expectBalance(family, family.mia, 2);
  });

  it('a parent hands it over, or says not now and the stars come back', async () => {
    await ask('given', 'ice-cream');
    await settled(family, 'rewardRequests', 'given', (value) => status(value) === 'waiting');
    const given = await callAs<{ status: string }>(family.sam, 'settleReward', {
      householdId: family.householdId,
      requestId: 'given',
      decision: 'fulfil',
    });
    expect(given.status).toBe('fulfilled');
    await expectBalance(family, family.mia, 2);

    await aReward('small', 1);
    await ask('declined', 'small');
    await settled(family, 'rewardRequests', 'declined', (value) => status(value) === 'waiting');
    await expectBalance(family, family.mia, 1);
    await callAs(family.sam, 'settleReward', {
      householdId: family.householdId,
      requestId: 'declined',
      decision: 'decline',
    });
    await expectBalance(family, family.mia, 2);
    await expectRefusal(
      callAs(family.sam, 'settleReward', {
        householdId: family.householdId,
        requestId: 'declined',
        decision: 'fulfil',
      }),
      'alreadySettled',
    );
  });

  it('a parent asking on a child’s behalf hands it over there and then', async () => {
    await ask('for-mia', 'ice-cream', family.samMember);
    const settledRequest = await settled(
      family,
      'rewardRequests',
      'for-mia',
      (value) => status(value) !== undefined,
    );
    expect(settledRequest).toMatchObject({ status: 'fulfilled', settledBy: family.samMember });
    await expectBalance(family, family.mia, 2);
  });

  it('refuses a reward that is gone, and anybody who is not a kid', async () => {
    await ask('gone', 'no-such-reward');
    expect(
      await settled(family, 'rewardRequests', 'gone', (value) => status(value) !== undefined),
    ).toMatchObject({ status: 'refused', refusal: 'rewardGone' });

    const parent = await addProfile(family.householdId, 'Alex', 'parent');
    await household(family.householdId).collection('rewardRequests').doc('adult').set({
      rewardId: 'ice-cream',
      memberId: parent,
      requestedBy: parent,
      requestedAt: new Date(),
    });
    expect(
      await settled(family, 'rewardRequests', 'adult', (value) => status(value) !== undefined),
    ).toMatchObject({ status: 'refused', refusal: 'notAKid' });
  });

  it('only family settles a reward', async () => {
    await ask('waiting', 'ice-cream');
    await settled(family, 'rewardRequests', 'waiting', (value) => status(value) === 'waiting');
    const body = { householdId: family.householdId, requestId: 'waiting', decision: 'decline' };
    await expectRefusal(
      callAs(await aKidDevice(family, family.mia), 'settleReward', body),
      'kidAccount',
    );
    await expectRefusal(callAs(await aMember(family, 'helper'), 'settleReward', body), 'notFamily');
    await expectRefusal(
      callAs(family.sam, 'settleReward', { ...body, requestId: 'nope' }),
      'requestNotFound',
    );
    await expectBalance(family, family.mia, 2);
  });
});
