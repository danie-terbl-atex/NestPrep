import type { DocumentReference } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { monthKeyIn } from '../../src/ai/usage_rules';
import { mondayOf, weekKeyOf } from '../../src/plan_week/iso_week';
import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { adminBucket, adminDb, callAs, clearFirestore, type TestUser } from './emulator_harness';

/**
 * `lunchPhoto` end to end, over HTTP with a real token (lunch-box ADR-0015,
 * BE-14). The emulator's image model hands back a bundled JPEG, so nothing
 * leaves the machine; everything else — the grant, premium, the plan read,
 * the cache claimed in a transaction, the cap, the ledger, the upload — is
 * the real code path.
 */

const MONDAY = '2026-10-05';
const SATURDAY = '2026-10-10';
const WEEK = weekKeyOf(mondayOf(MONDAY));
const MONTH = monthKeyIn('Africa/Johannesburg', new Date());

interface Home {
  readonly sam: TestUser;
  readonly householdId: string;
  readonly childId: string;
}

const home = (householdId: string): DocumentReference =>
  adminDb().collection('households').doc(householdId);

const pick = (itemId: string, name: string): Record<string, unknown> => ({
  itemId,
  name,
  allergens: [],
});

const CATALOGUE_MONDAY = {
  '1_main': pick('seed-cheese-tomato', 'Cheese and tomato sandwich'),
  '1_fruit': pick('seed-apple', 'Apple slices'),
};

async function aHousehold(premium: boolean): Promise<Home> {
  const { sam, householdId } = await householdOfTwo();
  const kid = home(householdId).collection('members').doc();
  await kid.set({ displayName: 'Zola', color: 'mint', role: 'kid', claimedBy: null });
  if (premium) {
    await home(householdId)
      .collection('entitlement')
      .doc('current')
      .set({ premiumUntil: new Date(Date.now() + 86_400_000) });
  }
  return { sam, householdId, childId: kid.id };
}

async function givenThePlan(
  { householdId, childId }: Home,
  slots: Record<string, unknown>,
): Promise<void> {
  await home(householdId)
    .collection('lunchPlans')
    .doc(`${childId}_${WEEK}`)
    .set({ childId, week: WEEK, weekStart: mondayOf(MONDAY), slots, feedback: {} });
}

type Photo = { status: 'ready'; path: string } | { status: 'pending' };

const photoOf = (household: Home, date = MONDAY): Promise<Photo> =>
  callAs<Photo>(household.sam, 'lunchPhoto', {
    householdId: household.householdId,
    childId: household.childId,
    date,
  });

async function callsCharged(householdId: string): Promise<unknown> {
  return (await home(householdId).collection('aiUsage').doc(MONTH).get()).get('calls');
}

beforeEach(async () => {
  await clearFirestore();
});

describe('who may picture a box', () => {
  it('refuses a household without premium, before anything is spent', async () => {
    const household = await aHousehold(false);
    await givenThePlan(household, CATALOGUE_MONDAY);
    await expectRefusal(photoOf(household), 'premiumRequired');
    expect(await callsCharged(household.householdId)).toBeUndefined();
  });

  it('refuses somebody who is not in the household', async () => {
    const household = await aHousehold(true);
    const stranger = await householdOfTwo();
    await expectRefusal(
      callAs(stranger.sam, 'lunchPhoto', {
        householdId: household.householdId,
        childId: household.childId,
        date: MONDAY,
      }),
      'notAMember',
    );
  });
});

describe('a box with nothing in it', () => {
  it('is refused as empty, on a school day with no plan and on a weekend', async () => {
    const household = await aHousehold(true);
    await expectRefusal(photoOf(household), 'emptyBox');
    await givenThePlan(household, CATALOGUE_MONDAY);
    await expectRefusal(photoOf(household, SATURDAY), 'emptyBox');
    expect(await callsCharged(household.householdId)).toBeUndefined();
  });
});

describe('a box of catalogue foods', () => {
  it('is pictured once, shared, and charged to the household that asked', async () => {
    const household = await aHousehold(true);
    await givenThePlan(household, CATALOGUE_MONDAY);

    const photo = await photoOf(household);
    expect(photo.status).toBe('ready');
    const path = photo.status === 'ready' ? photo.path : '';
    expect(path).toMatch(/^lunchPhotos\/[0-9a-f]{40}\.jpg$/);

    const [metadata] = await adminBucket().file(path).getMetadata();
    expect(metadata.contentType).toBe('image/jpeg');
    expect(metadata.cacheControl).toBe('public, max-age=31536000');
    expect(await callsCharged(household.householdId)).toBe(1);

    const key = path.slice('lunchPhotos/'.length, -'.jpg'.length);
    const cached = await adminDb().collection('lunchPhotos').doc(key).get();
    expect(cached.data()).toMatchObject({ status: 'ready', path, promptVersion: 'v1' });
  });

  it('asked for again, or by another household, is the same picture at no cost', async () => {
    const first = await aHousehold(true);
    await givenThePlan(first, CATALOGUE_MONDAY);
    const made = await photoOf(first);
    expect(await photoOf(first)).toEqual(made);

    const second = await aHousehold(true);
    await givenThePlan(second, {
      ...CATALOGUE_MONDAY,
      '1_fruit': pick('seed-apple', 'Apples, peeled'),
    });
    expect(await photoOf(second)).toEqual(made);
    expect(await callsCharged(first.householdId)).toBe(1);
    expect(await callsCharged(second.householdId)).toBeUndefined();
  });
});

describe('a box with something of the family’s own', () => {
  it('is pictured under the household', async () => {
    const household = await aHousehold(true);
    await givenThePlan(household, {
      ...CATALOGUE_MONDAY,
      '1_treat': pick('item-ouma', 'Ouma’s rusks'),
    });
    const photo = await photoOf(household);
    expect(photo.status).toBe('ready');
    const path = photo.status === 'ready' ? photo.path : '';
    expect(path).toMatch(
      new RegExp(`^households/${household.householdId}/lunchPhotos/[0-9a-f]{40}\\.jpg$`),
    );
    const [exists] = await adminBucket().file(path).exists();
    expect(exists).toBe(true);
    expect(await callsCharged(household.householdId)).toBe(1);
  });
});

describe('a picture the model will not make', () => {
  it('is refused, refunded, and can be asked for again', async () => {
    const household = await aHousehold(true);
    await givenThePlan(household, {
      '1_main': pick('item-mystery', 'Mystery sandwich'),
    });
    await adminDb().collection('aiEmulator').doc('lunchPhoto').set({ failWith: 'blocked' });
    await expectRefusal(photoOf(household), 'aiDeclined');
    expect(await callsCharged(household.householdId)).toBe(0);
    const left = await home(household.householdId).collection('lunchPhotos').get();
    expect(left.size).toBe(0);

    await adminDb().collection('aiEmulator').doc('lunchPhoto').delete();
    expect((await photoOf(household)).status).toBe('ready');
  });
});
