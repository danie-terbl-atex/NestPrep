import type { DocumentReference } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { monthKeyIn } from '../../src/ai/usage_rules';
import { mondayOf, weekKeyOf } from '../../src/plan_week/iso_week';
import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { adminDb, callAs, clearFirestore, signUp, type TestUser } from './emulator_harness';

/**
 * Jev's two decisions end to end over HTTP (foundation ADR-0021), against the
 * emulator's decision model: canned answers from `aiEmulator/{label}`, a sure
 * yes for anything not canned, nothing leaving the machine.
 */

const MONTH = monthKeyIn('Africa/Johannesburg', new Date());
const NEXT_WEEK = weekKeyOf(
  mondayOf(new Date(Date.now() + 7 * 86_400_000).toISOString().slice(0, 10)),
);

const home = (householdId: string): DocumentReference =>
  adminDb().collection('households').doc(householdId);

const canned = (label: string, data: Record<string, unknown>): Promise<unknown> =>
  adminDb().collection('aiEmulator').doc(label).set(data);

const noul = (value: number): Record<string, unknown> => ({ type: 'noul', noul: value });

async function callsCharged(householdId: string): Promise<unknown> {
  return (await home(householdId).collection('aiUsage').doc(MONTH).get()).get('calls');
}

beforeEach(async () => {
  await clearFirestore();
});

describe('ranking a grocery line’s Checkers matches', () => {
  const products = [
    { productId: 'choc', name: 'Chocolate Milk 1L', brand: 'Clover', priceCents: 3299 },
    { productId: 'full', name: 'Full Cream Milk 2L', brand: null, priceCents: 3499 },
  ];
  const rank = (user: TestUser, householdId: string): Promise<{ ranked: unknown[] }> =>
    callAs(user, 'rankProductMatches', { householdId, item: 'Milk', products });

  it('puts Jev’s best first for a member, and charges the month nothing', async () => {
    const { sam, householdId } = await householdOfTwo();
    await canned('productMatch', { answers: { p0: noul(0.04), p1: noul(0.93) } });
    expect(await rank(sam, householdId)).toEqual({
      ranked: [
        { productId: 'full', fit: 0.93 },
        { productId: 'choc', fit: 0.04 },
      ],
    });
    expect(await callsCharged(householdId)).toBeUndefined();
  });

  it('refuses somebody outside the household', async () => {
    const { householdId } = await householdOfTwo();
    await expectRefusal(rank(await signUp(), householdId), 'not-a-member');
  });

  it('is refused when switched off, and when Jev is down', async () => {
    const { sam, householdId } = await householdOfTwo();
    await adminDb()
      .doc('appConfig/ai')
      .set({ features: { productMatch: false } });
    await expectRefusal(rank(sam, householdId), 'aiSwitchedOff');
    await adminDb().doc('appConfig/ai').delete();
    await canned('productMatch', { failWith: 'transient' });
    await expectRefusal(rank(sam, householdId), 'aiUnavailable');
  });
});

describe('building the week from what the store has', () => {
  async function aPremiumHousehold(): Promise<{
    sam: TestUser;
    householdId: string;
    childId: string;
  }> {
    const { sam, householdId } = await householdOfTwo();
    const kid = home(householdId).collection('members').doc();
    await kid.set({ displayName: 'Zola', color: 'mint', role: 'kid', claimedBy: null });
    await home(householdId).collection('familyProfiles').doc(kid.id).set({ isChild: true });
    await home(householdId)
      .collection('entitlement')
      .doc('current')
      .set({ premiumUntil: new Date(Date.now() + 86_400_000) });
    return { sam, householdId, childId: kid.id };
  }

  interface Week {
    lunches: { productId: string; day: number }[];
    packs: unknown[];
    callsLeft: number;
  }

  const product = (
    productId: string,
    name: string,
    packQuantity: number | null,
  ): Record<string, unknown> => ({
    productId,
    name,
    brand: null,
    priceCents: 3000,
    isOnPromotion: false,
    allergens: [],
    allergensKnown: true,
    packQuantity,
  });

  const build = (sam: TestUser, householdId: string, childId: string): Promise<Week> =>
    callAs<Week>(sam, 'buildLunchWeek', {
      householdId,
      week: NEXT_WEEK,
      childIds: [childId],
      slots: ['fruit'],
      ideas: [
        {
          id: 'fruit',
          slot: 'fruit',
          childIds: [childId],
          products: [
            product('cups', 'Fruit cups 4 x 113g', 4),
            product('juice', 'Apple juice 2L', null),
          ],
        },
      ],
    });

  it('packs every open box from what Jev says fits, as one charged call', async () => {
    const { sam, householdId, childId } = await aPremiumHousehold();
    await canned('lunchWeek', { answers: { 'fit|p-2': noul(0.05) } });
    const week = await build(sam, householdId, childId);
    expect(week.lunches).toHaveLength(5);
    expect(week.lunches.every((l) => l.productId === 'cups')).toBe(true);
    expect(week.packs).toEqual([{ productId: 'cups', boxesPerPack: 4 }]);
    expect(week.callsLeft).toBe(99);
    expect(await callsCharged(householdId)).toBe(1);
  });

  it('refunds the call when Jev is down', async () => {
    const { sam, householdId, childId } = await aPremiumHousehold();
    await canned('lunchWeek', { failWith: 'transient' });
    await expectRefusal(build(sam, householdId, childId), 'aiUnavailable');
    expect(await callsCharged(householdId)).toBe(0);
  });
});
