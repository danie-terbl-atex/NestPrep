import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { recountHouseholdSize } from '../../src/household/keep_household_size';
import { adminDb, callAs, clearFirestore, closeAdmin, signUp } from './emulator_harness';
import { eventually } from './product_analytics_fixture';

/**
 * `entitlement/size` — how many people a household holds, which the `members`
 * rules read for the free plan's four (subscriptions ADR-0008).
 */
describe('a household’s size', () => {
  beforeEach(clearFirestore);
  afterAll(closeAdmin);

  async function aNewHousehold(): Promise<string> {
    const { householdId } = await callAs<{ householdId: string }>(
      await signUp(),
      'createHousehold',
      {
        name: 'The Parkers',
        timeZone: 'Africa/Johannesburg',
        adminDisplayName: 'Sam Parent',
        adminColor: 'violet',
      },
    );
    return householdId;
  }

  const members = (householdId: string): FirebaseFirestore.CollectionReference =>
    adminDb().collection(`households/${householdId}/members`);

  async function sizeOf(householdId: string): Promise<unknown> {
    return (await adminDb().doc(`households/${householdId}/entitlement/size`).get()).get('count');
  }

  const sizeBecomes = (householdId: string, count: number): Promise<unknown> =>
    eventually(
      () => sizeOf(householdId),
      (value) => value === count,
    );

  it('is one from the moment the household is made', async () => {
    const householdId = await aNewHousehold();
    expect(await sizeOf(householdId)).toBe(1);
  });

  it('follows every profile made and removed, claimed or not', async () => {
    const householdId = await aNewHousehold();
    const gran = members(householdId).doc('m-gran');
    await gran.set({ displayName: 'Gran', color: 'mint', role: 'parent', claimedBy: null });
    await members(householdId)
      .doc('m-kid')
      .set({ displayName: 'Kid', color: 'sky', role: 'kid', claimedBy: null });
    expect(await sizeBecomes(householdId, 3)).toBe(3);

    await gran.delete();
    expect(await sizeBecomes(householdId, 2)).toBe(2);
  });

  it('is not moved by a profile being renamed', async () => {
    const householdId = await aNewHousehold();
    await members(householdId)
      .doc('m-gran')
      .set({ displayName: 'Gran', color: 'mint', role: 'parent', claimedBy: null });
    await sizeBecomes(householdId, 2);
    await adminDb().doc(`households/${householdId}/entitlement/size`).set({ count: 7 });
    const everybody = await members(householdId).get();
    await everybody.docs[0]?.ref.update({ displayName: 'Sam P' });
    await new Promise((resolve) => setTimeout(resolve, 2_000));
    expect(await sizeOf(householdId)).toBe(7);
  });

  it('heals a count that was wrong the next time it is counted', async () => {
    const householdId = await aNewHousehold();
    await adminDb().doc(`households/${householdId}/entitlement/size`).set({ count: 9 });
    expect(await recountHouseholdSize(adminDb(), householdId)).toBe(1);
    expect(await sizeOf(householdId)).toBe(1);
  });

  it('writes nothing under a household that has ended', async () => {
    expect(await recountHouseholdSize(adminDb(), 'h-gone')).toBeNull();
    expect((await adminDb().doc('households/h-gone/entitlement/size').get()).exists).toBe(false);
  });
});
