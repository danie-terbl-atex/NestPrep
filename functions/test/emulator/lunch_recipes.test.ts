import type { DocumentReference } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { HOUSEHOLD_TIME_ZONE, nextWeekIn } from './household_week';
import { adminDb, callAs, clearFirestore, signUp, type TestUser } from './emulator_harness';

/**
 * AI lunch mains as real recipes, end to end over HTTP (lunch-box ADR-0021,
 * recipes ADR-0002): a dish placed in the week and costed by its ingredients,
 * then saved as the household's recipe by the one Function allowed to.
 */

const NEXT_WEEK = nextWeekIn(HOUSEHOLD_TIME_ZONE, new Date());

const home = (householdId: string): DocumentReference =>
  adminDb().collection('households').doc(householdId);

beforeEach(async () => {
  await clearFirestore();
});

async function aPremiumHousehold(): Promise<{
  sam: TestUser;
  thandi: TestUser;
  householdId: string;
  childId: string;
}> {
  const { sam, thandi, householdId } = await householdOfTwo();
  const kid = home(householdId).collection('members').doc();
  await kid.set({ displayName: 'Zola', color: 'mint', role: 'kid', claimedBy: null });
  await home(householdId).collection('familyProfiles').doc(kid.id).set({ isChild: true });
  await home(householdId)
    .collection('entitlement')
    .doc('current')
    .set({ premiumUntil: new Date(Date.now() + 86_400_000) });
  return { sam, thandi, householdId, childId: kid.id };
}

const product = (productId: string, name: string, priceCents: number): Record<string, unknown> => ({
  productId,
  name,
  brand: null,
  priceCents,
  isOnPromotion: false,
  allergens: [],
  allergensKnown: true,
  packQuantity: 8,
});

describe('a dish in the week', () => {
  it('is placed under its own id and answers with the products it is bought as', async () => {
    const { sam, householdId, childId } = await aPremiumHousehold();
    const week = await callAs<{
      lunches: { productId: string }[];
      packs: { productId: string; boxesPerPack: number }[];
      dishes: { ideaId: string; parts: { ingredient: string; productId: string }[] }[];
    }>(sam, 'buildLunchWeek', {
      householdId,
      week: NEXT_WEEK,
      childIds: [childId],
      slots: ['main'],
      ideas: [
        {
          id: 'idea-1',
          slot: 'main',
          childIds: [childId],
          products: [],
          dish: {
            name: 'Chicken wrap',
            ingredients: [
              {
                name: 'Wholewheat tortillas',
                products: [product('tortillas', 'Tortillas 8 Pack', 3000)],
              },
              { name: 'Chicken strips', products: [product('chicken', 'Chicken Strips', 6000)] },
            ],
          },
        },
      ],
    });
    expect(week.lunches).toHaveLength(5);
    expect(week.lunches.every((lunch) => lunch.productId === 'dish:idea-1')).toBe(true);
    expect(week.dishes).toEqual([
      {
        ideaId: 'idea-1',
        parts: [
          { ingredient: 'Wholewheat tortillas', productId: 'tortillas' },
          { ingredient: 'Chicken strips', productId: 'chicken' },
        ],
      },
    ]);
    expect(week.packs.map((pack) => pack.productId).sort()).toEqual(['chicken', 'tortillas']);
  });
});

describe('saving the dishes a parent uses (saveLunchRecipes)', () => {
  const wrap = {
    name: 'Mexican wholewheat wrap',
    summary: 'Chicken and corn in a soft wrap.',
    ingredients: [
      { name: 'Wholewheat tortillas', quantity: 1, unit: null },
      { name: 'Chicken strips', quantity: 50, unit: 'g' },
    ],
    steps: ['Fill and roll.'],
    prepMinutes: 10,
    prepAhead: false,
    prepNote: null,
    alsoContains: ['soy'],
  };
  const save = (
    user: TestUser,
    householdId: string,
  ): Promise<{ recipes: { id: string; allergens: string[] }[] }> =>
    callAs(user, 'saveLunchRecipes', { householdId, recipes: [wrap] });

  it('writes the household’s recipe once, with codes from its words and the labels, in its author’s name', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    const first = await save(sam, householdId);
    const [saved] = first.recipes;
    expect(saved?.id).toMatch(/^ai-[0-9a-f]{20}$/);
    expect(saved?.allergens).toEqual(['wheat', 'soy']);

    const stored = await home(householdId)
      .collection('recipes')
      .doc(saved?.id ?? '')
      .get();
    expect(stored.get('source')).toBe('ai');
    expect(stored.get('servings')).toBe(1);
    expect(stored.get('addedBy')).toEqual(expect.any(String));
    expect(stored.get('createdAt')).toBeDefined();

    // A retried *Use it* writes nothing twice.
    expect(await save(sam, householdId)).toEqual(first);
    expect((await home(householdId).collection('recipes').get()).size).toBe(1);
  });

  it('refuses somebody outside the household, and somebody who may not plan lunches', async () => {
    const { householdId } = await aPremiumHousehold();
    await expectRefusal(save(await signUp(), householdId), 'notAMember');
    const helpers = await householdOfTwo('helper');
    await home(helpers.householdId)
      .collection('entitlement')
      .doc('current')
      .set({ premiumUntil: new Date(Date.now() + 86_400_000) });
    await expectRefusal(save(helpers.thandi, helpers.householdId), 'lunchNotShared');
  });

  it('refuses a household without premium, and when planning is switched off', async () => {
    const { sam, householdId } = await householdOfTwo();
    await expectRefusal(save(sam, householdId), 'premiumRequired');
    const premium = await aPremiumHousehold();
    await adminDb().doc('appConfig/flags').set({ planMyWeek: false });
    await expectRefusal(save(premium.sam, premium.householdId), 'planWeekOff');
    await adminDb().doc('appConfig/flags').delete();
  });
});
