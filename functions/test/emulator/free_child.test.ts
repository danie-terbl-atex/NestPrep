import { beforeEach, describe, expect, it } from 'vitest';

import { markChild } from '../../src/family_profiles/set_child_profile';
import { IN_A_MONTH, NOW } from '../unit/subscriptions/store_fixtures';
import { adminDb, clearFirestore } from './emulator_harness';
import { givenAHousehold, givenPremiumUntil } from './subscriptions_fixture';

/**
 * Which child the free tier plans for (lunch-box ADR-0009): kept by
 * `setChildProfile` in the same transaction as the marking, in
 * `entitlement/freeChild`, where the lunch rules and the app read it.
 */
describe('markChild keeps the free tier’s child', () => {
  beforeEach(clearFirestore);

  const mark = (
    householdId: string,
    uid: string,
    memberId: string,
    isChild = true,
  ): Promise<void> => markChild(adminDb(), uid, { householdId, memberId, isChild }, NOW);

  async function freeChildOf(householdId: string): Promise<unknown> {
    const snapshot = await adminDb().doc(`households/${householdId}/entitlement/freeChild`).get();
    return snapshot.exists ? snapshot.get('memberId') : null;
  }

  it('is the first child marked', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await mark(home.id, home.admin, 'm-emma');
    expect(await freeChildOf(home.id)).toBe('m-emma');
  });

  it('stays the first child when a premium household marks more', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await mark(home.id, home.admin, 'm-emma');
    await givenPremiumUntil(home.id, IN_A_MONTH);
    await mark(home.id, home.admin, 'm-leo');
    await mark(home.id, home.admin, 'm-sam');
    expect(await freeChildOf(home.id)).toBe('m-emma');
  });

  it('passes to another child when the free one is unmarked', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await mark(home.id, home.admin, 'm-emma');
    await givenPremiumUntil(home.id, IN_A_MONTH);
    await mark(home.id, home.admin, 'm-leo');
    await mark(home.id, home.admin, 'm-emma', false);
    expect(await freeChildOf(home.id)).toBe('m-leo');
  });

  it('is nobody once the household has no child, and the next child marked after that', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await mark(home.id, home.admin, 'm-emma');
    await mark(home.id, home.admin, 'm-emma', false);
    expect(await freeChildOf(home.id)).toBeNull();
    await mark(home.id, home.admin, 'm-leo');
    expect(await freeChildOf(home.id)).toBe('m-leo');
  });

  it('is left alone when somebody who is not the free child is unmarked', async () => {
    const home = await givenAHousehold({ admin: 'uid-sam' });
    await mark(home.id, home.admin, 'm-emma');
    await givenPremiumUntil(home.id, IN_A_MONTH);
    await mark(home.id, home.admin, 'm-leo');
    await mark(home.id, home.admin, 'm-leo', false);
    expect(await freeChildOf(home.id)).toBe('m-emma');
  });
});
