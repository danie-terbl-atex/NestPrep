import { beforeEach, describe, expect, it } from 'vitest';

import {
  CallFailed,
  PROJECT_ID,
  REGION,
  adminDb,
  callAs,
  clearFirestore,
  signUp,
  type TestUser,
} from './emulator_harness';

/**
 * The subscriptions callables over HTTP, with real ID tokens — the wiring
 * and the authorisation, as the app meets them (BE-14; subscriptions
 * ADR-0001). The emulator has no store products configured, which is
 * exactly the state the app ships in until Daniel creates them: premium is
 * "not on sale yet", legibly, and nothing fails.
 */
const FUNCTIONS_HOST = process.env['FUNCTIONS_EMULATOR_HOST'] ?? '127.0.0.1:5001';

interface Offer {
  isAvailable: boolean;
  canBuy: boolean;
  cohort: string;
  featuredPlan: string;
  products: unknown[];
}

async function householdOf(admin: TestUser): Promise<string> {
  const { householdId } = await callAs<{ householdId: string }>(admin, 'createHousehold', {
    name: 'The Parkers',
    timeZone: 'Africa/Johannesburg',
    adminDisplayName: 'Sam',
    adminColor: 'violet',
  });
  return householdId;
}

async function addKid(householdId: string, memberId: string): Promise<void> {
  await adminDb()
    .doc(`households/${householdId}/members/${memberId}`)
    .set({ displayName: memberId, color: 'mint', role: 'kid', claimedBy: null });
}

async function reasonOf(promise: Promise<unknown>): Promise<string | undefined> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof CallFailed) return error.reason ?? error.status;
    throw error;
  }
  return undefined;
}

describe('getSubscriptionOffer', () => {
  beforeEach(clearFirestore);

  it('says premium is not on sale yet, and that this parent could buy it once it is', async () => {
    const sam = await signUp();
    const householdId = await householdOf(sam);
    const offer = await callAs<Offer>(sam, 'getSubscriptionOffer', { householdId });
    expect(offer).toEqual({
      isAvailable: false,
      canBuy: true,
      cohort: 'a',
      featuredPlan: 'yearly',
      products: [],
    });
  });

  it('refuses somebody outside the household, and nobody at all', async () => {
    const sam = await signUp();
    const stranger = await signUp();
    const householdId = await householdOf(sam);
    expect(await reasonOf(callAs(stranger, 'getSubscriptionOffer', { householdId }))).toBe(
      'notAMember',
    );
    expect(await reasonOf(callAs(null, 'getSubscriptionOffer', { householdId }))).toBe(
      'notSignedIn',
    );
  });
});

describe('verifyPurchase', () => {
  beforeEach(clearFirestore);

  it('refuses while nothing is on sale, before any store is asked', async () => {
    const sam = await signUp();
    const householdId = await householdOf(sam);
    const body = { householdId, store: 'playStore', verificationData: 'token', trigger: 'direct' };
    expect(await reasonOf(callAs(sam, 'verifyPurchase', body))).toBe('premiumUnavailable');
    expect((await adminDb().collection('storePurchases').get()).size).toBe(0);
  });

  it('refuses a body that is not a purchase to verify', async () => {
    const sam = await signUp();
    const householdId = await householdOf(sam);
    const body = { householdId, store: 'webStore', verificationData: 'token', trigger: null };
    expect(await reasonOf(callAs(sam, 'verifyPurchase', body))).toBe('badRequest');
  });
});

describe('setChildProfile', () => {
  beforeEach(clearFirestore);

  it('marks the first child, and refuses the second on the free tier', async () => {
    const sam = await signUp();
    const householdId = await householdOf(sam);
    await addKid(householdId, 'm-emma');
    await addKid(householdId, 'm-leo');

    await callAs(sam, 'setChildProfile', { householdId, memberId: 'm-emma', isChild: true });
    expect(
      await reasonOf(
        callAs(sam, 'setChildProfile', { householdId, memberId: 'm-leo', isChild: true }),
      ),
    ).toBe('premiumRequired');

    const children = await adminDb()
      .collection(`households/${householdId}/familyProfiles`)
      .where('isChild', '==', true)
      .get();
    expect(children.docs.map((doc) => doc.id)).toEqual(['m-emma']);
  });

  it('refuses somebody outside the household', async () => {
    const sam = await signUp();
    const stranger = await signUp();
    const householdId = await householdOf(sam);
    await addKid(householdId, 'm-emma');
    expect(
      await reasonOf(
        callAs(stranger, 'setChildProfile', { householdId, memberId: 'm-emma', isChild: true }),
      ),
    ).toBe('notAMember');
  });
});

describe('appStoreNotifications', () => {
  const url = `http://${FUNCTIONS_HOST}/${PROJECT_ID}/${REGION}/appStoreNotifications`;

  it('answers only a POST', async () => {
    expect((await fetch(url)).status).toBe(405);
  });

  it('refuses a body with no signed payload, and a payload nobody signed', async () => {
    const post = (body: unknown): Promise<Response> =>
      fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
    expect((await post({ hello: 'apple' })).status).toBe(400);
    const unsigned = [
      Buffer.from(JSON.stringify({ alg: 'ES256', x5c: ['a', 'b', 'c'] })).toString('base64url'),
      Buffer.from(JSON.stringify({ notificationType: 'SUBSCRIBED' })).toString('base64url'),
      'c2lnbmF0dXJl',
    ].join('.');
    expect((await post({ signedPayload: unsigned })).status).toBe(400);
  });
});
