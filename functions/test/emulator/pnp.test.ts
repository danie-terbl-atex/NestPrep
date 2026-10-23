import { beforeEach, describe, expect, it } from 'vitest';

import { FirestorePnpLinkStore } from '../../src/pnp/firestore_pnp_link_store';
import type { PnpSessionLink } from '../../src/pnp/pnp_link_store';
import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { adminDb, callAs, clearFirestore, signUp, type TestUser } from './emulator_harness';

/**
 * Add to Pick n Pay end to end, over HTTP with a real token (add-to-pnp
 * ADR-0003, ADR-0004, BE-14): start a link, complete it with the code the web
 * view would catch, fill the cart, push again, unlink — against the emulator's
 * scripted PnP, which reaches nothing — and each refusal told apart.
 */
interface Status {
  linked: boolean;
  linkedAt: string | null;
}

interface Pushed {
  added: { itemId: string; productId: string; name: string; priceCents: number }[];
  skipped: { itemId: string; reason: string }[];
  cartItemCount: number;
  cartTotalCents: number;
}

const CHIPS = '000000000000838685_EA';

async function link(user: TestUser): Promise<Status> {
  const { authorizeUrl } = await callAs<{ authorizeUrl: string }>(user, 'pnpStartLink', {});
  const state = new URL(authorizeUrl).searchParams.get('state') ?? '';
  return callAs<Status>(user, 'pnpCompleteLink', { code: 'emulator-code', state });
}

async function anItem(householdId: string, id: string, productId: string | null): Promise<void> {
  await adminDb()
    .collection('households')
    .doc(householdId)
    .collection('groceryItems')
    .doc(id)
    .set({
      name: 'Chips',
      quantity: '3 packs',
      addedBy: 'm-sam',
      addedAt: new Date(),
      boughtAt: null,
      boughtBy: null,
      ...(productId === null
        ? {}
        : {
            productMatch: {
              retailer: 'pickNPay',
              productId,
              articleCode: productId.split('_')[0],
              unitOfMeasure: productId.split('_')[1],
              name: 'Simba Chutney 120g',
              brand: null,
              priceCents: 2199,
              currency: 'ZAR',
              imageId: null,
              pickedBy: 'm-sam',
              pickedAt: new Date(),
            },
          }),
    });
}

beforeEach(async () => {
  await clearFirestore();
});

describe('linking a Pick n Pay account', () => {
  it('starts on PnP’s own page and completes with the caught code, holding only sealed tokens', async () => {
    const sam = await signUp();
    expect(await callAs<Status>(sam, 'pnpLinkStatus', {})).toEqual({
      linked: false,
      linkedAt: null,
    });
    const { authorizeUrl } = await callAs<{ authorizeUrl: string }>(sam, 'pnpStartLink', {});
    const url = new URL(authorizeUrl);
    expect(url.host).toBe('login.pnp.co.za');
    expect(url.searchParams.get('redirect_uri')).toBe('https://www.pnp.co.za/oidc_login');
    const state = url.searchParams.get('state') ?? '';
    const linked = await callAs<Status>(sam, 'pnpCompleteLink', { code: 'emulator-code', state });
    expect(linked.linked).toBe(true);
    expect(await callAs<Status>(sam, 'pnpLinkStatus', {})).toEqual(linked);
    const stored = JSON.stringify((await adminDb().doc(`pnpLinks/${sam.uid}`).get()).data());
    expect(stored).not.toContain('emulator-access');
    expect(stored).not.toContain('emulator-refresh');
  });

  it('refuses a forged state, a code PnP refuses, and a completion with nothing started', async () => {
    const sam = await signUp();
    await expectRefusal(
      callAs(sam, 'pnpCompleteLink', { code: 'emulator-code', state: 'nothing' }),
      'pnp-no-pending-link',
    );
    await callAs(sam, 'pnpStartLink', {});
    await expectRefusal(
      callAs(sam, 'pnpCompleteLink', { code: 'emulator-code', state: 'forged' }),
      'pnp-link-refused',
    );
    const { authorizeUrl } = await callAs<{ authorizeUrl: string }>(sam, 'pnpStartLink', {});
    const state = new URL(authorizeUrl).searchParams.get('state') ?? '';
    await expectRefusal(
      callAs(sam, 'pnpCompleteLink', { code: 'wrong-code', state }),
      'pnp-link-refused',
    );
  });

  it('refuses while the switch is off, and still answers status and unlink', async () => {
    const sam = await signUp();
    await link(sam);
    await adminDb().doc('appConfig/flags').set({ addToPnp: false });
    await expectRefusal(callAs(sam, 'pnpStartLink', {}), 'pnp-switched-off');
    expect((await callAs<Status>(sam, 'pnpLinkStatus', {})).linked).toBe(true);
    expect(await callAs(sam, 'pnpUnlink', {})).toEqual({ linked: false });
    expect((await adminDb().doc(`pnpLinks/${sam.uid}`).get()).exists).toBe(false);
  });

  it('refuses somebody who is not signed in', async () => {
    await expect(callAs(null, 'pnpLinkStatus', {})).rejects.toThrow(/UNAUTHENTICATED/);
  });
});

describe('filling the PnP cart', () => {
  it('puts the asked packs in, skips the rest, and a second push changes nothing', async () => {
    const { sam, householdId } = await householdOfTwo();
    await link(sam);
    await anItem(householdId, 'chips', CHIPS);
    await anItem(householdId, 'typed', null);
    await anItem(householdId, 'meat', '000000000000123456_KGM');
    const body = {
      householdId,
      itemIds: ['chips', 'typed', 'meat', 'nothing'],
      quantities: { chips: 3 },
    };
    const pushed = await callAs<Pushed>(sam, 'pnpPushToCart', body);
    expect(pushed.added.map((line) => line.itemId)).toEqual(['chips']);
    expect(pushed.skipped).toEqual([
      { itemId: 'typed', reason: 'no-match' },
      { itemId: 'meat', reason: 'weighed-item' },
      { itemId: 'nothing', reason: 'not-found' },
    ]);
    expect(pushed.cartItemCount).toBe(3);
    const again = await callAs<Pushed>(sam, 'pnpPushToCart', body);
    expect(again.cartItemCount).toBe(3);
  });

  it('a product PnP has too little of is skipped, and a raise stops at its order limit', async () => {
    const { sam, householdId } = await householdOfTwo();
    await link(sam);
    await anItem(householdId, 'scarce', '000300000000111111_EA');
    await anItem(householdId, 'limited', '000200000000222222_EA');
    const pushed = await callAs<Pushed>(sam, 'pnpPushToCart', {
      householdId,
      itemIds: ['scarce', 'limited'],
      quantities: { scarce: 2, limited: 5 },
    });
    expect(pushed.skipped).toEqual([{ itemId: 'scarce', reason: 'low-stock' }]);
    expect(pushed.added.map((line) => line.itemId)).toEqual(['limited']);
    expect(pushed.cartItemCount).toBe(2);
  });

  it('refuses a member with no link, a stranger, and a switched-off feature', async () => {
    const { sam, householdId } = await householdOfTwo();
    await anItem(householdId, 'chips', CHIPS);
    const body = { householdId, itemIds: ['chips'] };
    await expectRefusal(callAs(sam, 'pnpPushToCart', body), 'pnp-link-expired');
    const stranger = await signUp();
    await link(stranger);
    await expectRefusal(callAs(stranger, 'pnpPushToCart', body), 'not-a-member');
    await adminDb().doc('appConfig/flags').set({ addToPnp: false });
    await expectRefusal(callAs(sam, 'pnpPushToCart', body), 'pnp-switched-off');
  });
});

describe('the stored link, against real Firestore', () => {
  const session = (sealed: string): PnpSessionLink => ({
    sealed,
    accessExpiresAt: new Date('2026-10-12T11:00:00Z'),
    linkedAt: new Date('2026-10-12T10:00:00Z'),
  });

  it('a refresh replaces only the session it was refreshed from (compare-and-swap)', async () => {
    const links = new FirestorePnpLinkStore(adminDb());
    await links.saveSession('uid-cas', session('v1.first'));
    expect(await links.replaceSession('uid-cas', 'v1.first', session('v1.second'))).toBe(
      'replaced',
    );
    expect(await links.replaceSession('uid-cas', 'v1.first', session('v1.third'))).toBe('changed');
    expect((await links.read('uid-cas'))?.session?.sealed).toBe('v1.second');
  });

  it('a refresh that lands after an unlink writes nothing back', async () => {
    const links = new FirestorePnpLinkStore(adminDb());
    await links.saveSession('uid-gone', session('v1.first'));
    await links.remove('uid-gone');
    expect(await links.replaceSession('uid-gone', 'v1.first', session('v1.second'))).toBe('gone');
    expect((await adminDb().doc('pnpLinks/uid-gone').get()).exists).toBe(false);
  });
});
