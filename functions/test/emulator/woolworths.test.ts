import { randomUUID } from 'node:crypto';

import { beforeEach, describe, expect, it } from 'vitest';

import { FirestoreWoolworthsLinkStore } from '../../src/woolworths/firestore_woolworths_link_store';
import type { WoolworthsSessionLink } from '../../src/woolworths/woolworths_link_store';
import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { adminDb, callAs, clearFirestore, signUp, type TestUser } from './emulator_harness';

interface Status {
  linked: boolean;
  linkedAt?: string;
  emailMasked?: string;
}

interface Pushed {
  added: { itemId: string; productId: string; name: string; priceCents: number }[];
  skipped: { itemId: string; reason: string }[];
  cartItemCount: number;
  cartTotalCents: number;
}

const MILK = '20011697';

function emulatorRefreshToken(): string {
  return `emulator-woolworths-refresh-${randomUUID()}`;
}

async function link(user: TestUser): Promise<Status> {
  return callAs<Status>(user, 'woolworthsCompleteLink', { refreshToken: emulatorRefreshToken() });
}

async function anItem(
  householdId: string,
  id: string,
  sku: string | null,
  unit = 'EA',
): Promise<void> {
  await adminDb()
    .collection('households')
    .doc(householdId)
    .collection('groceryItems')
    .doc(id)
    .set({
      name: 'Milk',
      quantity: '2 L',
      addedBy: 'm-sam',
      addedAt: new Date(),
      boughtAt: null,
      boughtBy: null,
      ...(sku === null
        ? {}
        : {
            productMatch: {
              retailer: 'woolworths',
              productId: sku,
              articleCode: sku,
              unitOfMeasure: unit,
              name: 'Fresh Full Cream Milk 2 L',
              brand: null,
              priceCents: 4099,
              currency: 'ZAR',
              imageId: null,
              pickedBy: 'm-sam',
              pickedAt: new Date(),
            },
          }),
    });
}

async function premium(householdId: string): Promise<void> {
  await adminDb()
    .doc(`households/${householdId}/entitlement/current`)
    .set({ premiumUntil: new Date(Date.now() + 86_400_000) });
}

async function aPremiumHousehold(): Promise<{ sam: TestUser; householdId: string }> {
  const { sam, householdId } = await householdOfTwo();
  await premium(householdId);
  return { sam, householdId };
}

async function aPremiumMember(): Promise<TestUser> {
  return (await aPremiumHousehold()).sam;
}

beforeEach(async () => {
  await clearFirestore();
});

describe('linking a Woolworths account', () => {
  it('hands the phone the Cognito client, then links with only the refresh token, sealed', async () => {
    const sam = await aPremiumMember();
    expect(await callAs<Status>(sam, 'woolworthsLinkStatus', {})).toEqual({ linked: false });
    const client = await callAs<{ clientId: string; region: string }>(
      sam,
      'woolworthsStartLink',
      {},
    );
    expect(client.clientId).not.toBe('');
    expect(client.region).not.toBe('');
    const refreshToken = emulatorRefreshToken();
    const linked = await callAs<Status>(sam, 'woolworthsCompleteLink', { refreshToken });
    expect(linked).toEqual({
      linked: true,
      linkedAt: expect.any(String) as string,
      emailMasked: 'p***@o***.nest',
    });
    expect(await callAs<Status>(sam, 'woolworthsLinkStatus', {})).toEqual(linked);
    const stored = JSON.stringify((await adminDb().doc(`woolworthsLinks/${sam.uid}`).get()).data());
    expect(stored).not.toContain(refreshToken);
    expect(stored).not.toContain('parent@oakstreet.nest');
  });

  it('refuses a refresh token Cognito will not take', async () => {
    const sam = await aPremiumMember();
    await expectRefusal(
      callAs(sam, 'woolworthsCompleteLink', { refreshToken: 'not-a-real-token' }),
      'woolworths-link-rejected',
    );
    expect((await adminDb().doc(`woolworthsLinks/${sam.uid}`).get()).exists).toBe(false);
  });

  it('refuses while the switch is off, and still answers status and unlink', async () => {
    const sam = await aPremiumMember();
    await link(sam);
    await adminDb().doc('appConfig/flags').set({ addToWoolworths: false });
    await expectRefusal(callAs(sam, 'woolworthsStartLink', {}), 'woolworths-switched-off');
    await expectRefusal(link(sam), 'woolworths-switched-off');
    expect((await callAs<Status>(sam, 'woolworthsLinkStatus', {})).linked).toBe(true);
    expect(await callAs(sam, 'woolworthsUnlink', {})).toEqual({});
    expect((await adminDb().doc(`woolworthsLinks/${sam.uid}`).get()).exists).toBe(false);
  });

  it('refuses somebody who is not signed in', async () => {
    await expect(callAs(null, 'woolworthsLinkStatus', {})).rejects.toThrow(/UNAUTHENTICATED/);
  });

  it('links only for a member of a Premium household, and a lapsed one still unlinks', async () => {
    await expectRefusal(callAs(await signUp(), 'woolworthsStartLink', {}), 'premiumRequired');
    const free = await householdOfTwo();
    await expectRefusal(callAs(free.sam, 'woolworthsStartLink', {}), 'premiumRequired');
    await expectRefusal(link(free.sam), 'premiumRequired');
    const { sam, householdId } = await aPremiumHousehold();
    await link(sam);
    await adminDb().doc(`households/${householdId}/entitlement/current`).delete();
    expect((await callAs<Status>(sam, 'woolworthsLinkStatus', {})).linked).toBe(true);
    expect(await callAs(sam, 'woolworthsUnlink', {})).toEqual({});
  });
});

describe('filling the Dash cart', () => {
  it('adds the asked packs, skips the rest, and a second push changes nothing', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await link(sam);
    await anItem(householdId, 'milk', MILK);
    await anItem(householdId, 'typed', null);
    await anItem(householdId, 'meat', '2000000123456', 'KG');
    const body = {
      householdId,
      itemIds: ['milk', 'typed', 'meat', 'nothing'],
      quantities: { milk: 3 },
    };
    const pushed = await callAs<Pushed>(sam, 'woolworthsPushToCart', body);
    expect(pushed.added.map((line) => line.itemId)).toEqual(['milk']);
    expect(pushed.skipped).toEqual([
      { itemId: 'typed', reason: 'no-match' },
      { itemId: 'meat', reason: 'weighed-item' },
      { itemId: 'nothing', reason: 'not-found' },
    ]);
    expect(pushed.cartItemCount).toBe(3);
    const again = await callAs<Pushed>(sam, 'woolworthsPushToCart', body);
    expect(again.cartItemCount).toBe(3);
  });

  it('a product out of stock, short, or unknown is that item’s skip', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await link(sam);
    await anItem(householdId, 'gone', '00010000111');
    await anItem(householdId, 'short', '00020000222');
    await anItem(householdId, 'unknown', '99900000333');
    const pushed = await callAs<Pushed>(sam, 'woolworthsPushToCart', {
      householdId,
      itemIds: ['gone', 'short', 'unknown'],
      quantities: { gone: 2, short: 5 },
    });
    expect(pushed.skipped).toEqual([
      { itemId: 'unknown', reason: 'not-found' },
      { itemId: 'gone', reason: 'out-of-stock' },
      { itemId: 'short', reason: 'low-stock' },
    ]);
    expect(pushed.cartItemCount).toBe(2);
  });

  it('refuses a member with no link, a stranger, and a switched-off feature', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await anItem(householdId, 'milk', MILK);
    const body = { householdId, itemIds: ['milk'] };
    await expectRefusal(callAs(sam, 'woolworthsPushToCart', body), 'woolworths-not-linked');
    const stranger = await aPremiumMember();
    await link(stranger);
    await expectRefusal(callAs(stranger, 'woolworthsPushToCart', body), 'not-a-member');
    await adminDb().doc('appConfig/flags').set({ addToWoolworths: false });
    await expectRefusal(callAs(sam, 'woolworthsPushToCart', body), 'woolworths-switched-off');
  });

  it('refuses a free household', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await link(sam);
    await anItem(householdId, 'milk', MILK);
    await adminDb().doc(`households/${householdId}/entitlement/current`).delete();
    await expectRefusal(
      callAs(sam, 'woolworthsPushToCart', { householdId, itemIds: ['milk'] }),
      'premiumRequired',
    );
  });
});

describe('the stored link, against real Firestore', () => {
  const session = (sealed: string): WoolworthsSessionLink => ({
    sealed,
    idExpiresAt: new Date('2026-11-06T10:00:00Z'),
    linkedAt: new Date('2026-11-05T10:00:00Z'),
    emailMasked: 'd***@a***.io',
  });

  it('a refresh replaces only the session it was refreshed from (compare-and-swap)', async () => {
    const links = new FirestoreWoolworthsLinkStore(adminDb());
    await links.saveSession('uid-cas', session('v1.first'));
    expect(await links.replaceSession('uid-cas', 'v1.first', session('v1.second'))).toBe(
      'replaced',
    );
    expect(await links.replaceSession('uid-cas', 'v1.first', session('v1.third'))).toBe('changed');
    const stored = await links.read('uid-cas');
    expect(stored?.session?.sealed).toBe('v1.second');
    expect(stored?.session?.emailMasked).toBe('d***@a***.io');
  });

  it('a refresh that lands after an unlink writes nothing back', async () => {
    const links = new FirestoreWoolworthsLinkStore(adminDb());
    await links.saveSession('uid-gone', session('v1.first'));
    await links.remove('uid-gone');
    expect(await links.replaceSession('uid-gone', 'v1.first', session('v1.second'))).toBe('gone');
    expect((await adminDb().doc('woolworthsLinks/uid-gone').get()).exists).toBe(false);
  });
});
