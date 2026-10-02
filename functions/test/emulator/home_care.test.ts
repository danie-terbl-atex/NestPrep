import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { translationId } from '../../src/home_care/translation_id';
import { monthKey } from '../../src/home_care/translation_cap';
import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { adminDb, callAs, clearFirestore, signUp, type TestUser } from './emulator_harness';
import { eventually } from './product_analytics_fixture';

/**
 * Home care's server half end to end, over HTTP with a real token
 * (home-care ADR-0005, ADR-0006, BE-14): a helper's words translated once and
 * paid for from the month's cap, every refusal told apart by its reason; and a
 * product marked low arriving on the grocery list exactly once.
 */

interface Home {
  readonly sam: TestUser;
  readonly thandi: TestUser;
  readonly householdId: string;
}

interface Translated {
  translations: { text: string; translated: string }[];
}

/** Sam the admin and Thandi a helper on the helper defaults — home care `own`. */
function aHomeWithAHelper(): Promise<Home> {
  return householdOfTwo('helper');
}

const household = (home: Home): FirebaseFirestore.DocumentReference =>
  adminDb().collection('households').doc(home.householdId);

const usage = async (home: Home): Promise<unknown> =>
  (
    await household(home).collection('homeCareTranslationUsage').doc(monthKey(new Date())).get()
  ).get('characters');

function translate(
  user: TestUser,
  home: Home,
  texts: string[],
  language = 'zu',
): Promise<Translated> {
  return callAs<Translated>(user, 'translateHomeCareTexts', {
    householdId: home.householdId,
    language,
    texts,
  });
}

beforeEach(async () => {
  await clearFirestore();
});

describe('translateHomeCareTexts', () => {
  it('translates for the helper, stores each text, and charges the month for it', async () => {
    const home = await aHomeWithAHelper();
    const result = await translate(home.thandi, home, ['Open a window', 'Wipe clean']);
    expect(result.translations).toEqual([
      { text: 'Open a window', translated: '[zu] Open a window' },
      { text: 'Wipe clean', translated: '[zu] Wipe clean' },
    ]);
    const cached = await household(home)
      .collection('homeCareTranslations')
      .doc(translationId('Open a window', 'zu'))
      .get();
    expect(cached.get('text')).toBe('[zu] Open a window');
    expect(cached.get('engine')).toBe('emulator');
    expect(await usage(home)).toBe('Open a window'.length + 'Wipe clean'.length);
  });

  it('translates a text once: the second ask is served from the cache, free', async () => {
    const home = await aHomeWithAHelper();
    await translate(home.sam, home, ['Open a window']);
    const before = await usage(home);
    await translate(home.thandi, home, ['Open a window']);
    expect(await usage(home)).toBe(before);
  });

  it('refuses past the month’s cap, charges nothing, and still serves the cache', async () => {
    const home = await aHomeWithAHelper();
    await translate(home.sam, home, ['Open a window']);
    await household(home)
      .collection('homeCareTranslationUsage')
      .doc(monthKey(new Date()))
      .set({ characters: 19_995 });
    await expectRefusal(
      translate(home.thandi, home, ['Scrub the bath']),
      'translationLimitReached',
    );
    expect(await usage(home)).toBe(19_995);
    const cached = await translate(home.thandi, home, ['Open a window']);
    expect(cached.translations[0]?.translated).toBe('[zu] Open a window');
  });

  it('gives a premium household ten times the characters', async () => {
    const home = await aHomeWithAHelper();
    await household(home)
      .collection('homeCareTranslationUsage')
      .doc(monthKey(new Date()))
      .set({ characters: 19_995 });
    await household(home)
      .collection('entitlement')
      .doc('current')
      .set({ premiumUntil: Timestamp.fromMillis(Date.now() + 86_400_000) });
    await translate(home.thandi, home, ['Scrub the bath']);
    expect(await usage(home)).toBe(19_995 + 'Scrub the bath'.length);
  });

  it('refuses when the switch is off', async () => {
    const home = await aHomeWithAHelper();
    await adminDb().doc('appConfig/flags').set({ homeCareHelperLanguage: false });
    await expectRefusal(translate(home.thandi, home, ['Open a window']), 'translationSwitchedOff');
  });

  it('refuses a carer, whose grant has no home care, and a stranger', async () => {
    const carers = await householdOfTwo('carer');
    const nomsa = carers.thandi;
    const home = { ...carers, sam: nomsa };
    await expectRefusal(translate(nomsa, home, ['Open a window']), 'homeCareNotShared');
    const stranger = await signUp();
    await expectRefusal(translate(stranger, home, ['Open a window']), 'notAMember');
  });

  it('refuses English, which nothing is translated into, at the edge', async () => {
    const home = await aHomeWithAHelper();
    await expectRefusal(translate(home.thandi, home, ['Open a window'], 'en'), 'badRequest');
  });

  it('refuses somebody who is not signed in', async () => {
    const home = await aHomeWithAHelper();
    await expect(
      callAs(null, 'translateHomeCareTexts', {
        householdId: home.householdId,
        language: 'zu',
        texts: ['x'],
      }),
    ).rejects.toThrow(/UNAUTHENTICATED/);
  });
});

describe('a product marked low goes onto the grocery list', () => {
  async function aProduct(home: Home, name = 'Jik'): Promise<FirebaseFirestore.DocumentReference> {
    const product = household(home).collection('homeCareProducts').doc();
    await product.set({
      name,
      kind: 'bleach',
      whereKept: null,
      note: null,
      keepFromChildren: true,
      keepFromPets: false,
      createdBy: 'm-sam',
      createdAt: new Date(),
    });
    return product;
  }

  const mark = (
    product: FirebaseFirestore.DocumentReference,
    stock: string,
  ): Promise<FirebaseFirestore.WriteResult> =>
    product.update({ stock, stockChangedBy: 'm-thandi', stockChangedAt: new Date() });

  const lines = async (home: Home): Promise<FirebaseFirestore.DocumentData[]> =>
    (await household(home).collection('groceryItems').get()).docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));

  it('adds one line, from home care, in the marker’s name', async () => {
    const home = await aHomeWithAHelper();
    const product = await aProduct(home);
    await mark(product, 'low');
    const added = await eventually(
      () => lines(home),
      (found) => found.length > 0,
    );
    expect(added).toHaveLength(1);
    expect(added[0]).toMatchObject({
      id: `homeCare-${product.id}`,
      name: 'Jik',
      quantity: null,
      addedBy: 'm-thandi',
      boughtAt: null,
      boughtBy: null,
      source: 'homeCare',
      sourceId: product.id,
    });
  });

  it('adds nothing more when it goes from low to out', async () => {
    const home = await aHomeWithAHelper();
    const product = await aProduct(home);
    await mark(product, 'low');
    await eventually(
      () => lines(home),
      (found) => found.length > 0,
    );
    await household(home).collection('groceryItems').doc(`homeCare-${product.id}`).update({
      quantity: '2 bottles',
    });
    await mark(product, 'out');
    // Long enough for the trigger to have run and rewritten the line if it
    // were going to; the quantity somebody added is still there.
    await new Promise((resolve) => setTimeout(resolve, 3_000));
    const after = await lines(home);
    expect(after).toHaveLength(1);
    expect(after[0]?.['quantity']).toBe('2 bottles');
  });

  it('adds nothing when the same thing is already on the list, unbought', async () => {
    const home = await aHomeWithAHelper();
    await household(home).collection('groceryItems').doc('typed').set({
      name: '  jik ',
      quantity: null,
      addedBy: 'm-sam',
      addedAt: new Date(),
      boughtAt: null,
      boughtBy: null,
    });
    const product = await aProduct(home);
    await mark(product, 'low');
    await new Promise((resolve) => setTimeout(resolve, 3_000));
    expect((await lines(home)).map((line) => String(line['id']))).toEqual(['typed']);
  });

  it('keeps the product a member picked when a bought line is needed again', async () => {
    const home = await aHomeWithAHelper();
    const product = await aProduct(home);
    await mark(product, 'low');
    await eventually(
      () => lines(home),
      (found) => found.length > 0,
    );
    const pick = { retailer: 'checkers', productId: '5f0c1a2b3c4d5e6f7a8b9c0d', priceCents: 2999 };
    await household(home)
      .collection('groceryItems')
      .doc(`homeCare-${product.id}`)
      .update({ productMatch: pick, boughtAt: new Date(), boughtBy: 'm-sam' });
    await mark(product, 'full');
    await mark(product, 'low');
    const again = await eventually(
      () => lines(home),
      (found) => found[0]?.['boughtBy'] === null,
    );
    expect(again).toHaveLength(1);
    expect(again[0]?.['productMatch']).toEqual(pick);
  });

  it('adds nothing while the switch is off', async () => {
    const home = await aHomeWithAHelper();
    await adminDb().doc('appConfig/flags').set({ homeCareStock: false });
    const product = await aProduct(home);
    await mark(product, 'out');
    await new Promise((resolve) => setTimeout(resolve, 3_000));
    expect(await lines(home)).toEqual([]);
  });
});
