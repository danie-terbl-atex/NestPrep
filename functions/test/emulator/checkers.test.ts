import { beforeEach, describe, expect, it } from 'vitest';

import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { adminDb, callAs, clearFirestore, signUp, type TestUser } from './emulator_harness';

/**
 * Add to Checkers end to end, over HTTP with a real token (the Checkers build
 * contract, BE-14): link by code, fill the cart, unlink — against the
 * emulator's scripted Checkers, which sends no SMS and touches no real cart —
 * and each refusal told apart by its reason.
 */

interface Status {
  linked: boolean;
  expiresAt: string | null;
  mobileMasked: string | null;
}

interface Pushed {
  added: { itemId: string; productId: string; name: string; priceCents: number }[];
  skipped: { itemId: string; reason: string }[];
  cartItemCount: number;
  cartTotalCents: number;
}

const MILK = '5d3af63bf434cf8420737dd6';

async function link(user: TestUser, mobile = '082 555 1234'): Promise<Status> {
  await callAs(user, 'checkersRequestOtp', { mobile });
  return callAs<Status>(user, 'checkersVerifyOtp', { code: '123456' });
}

async function anItem(householdId: string, id: string, productId: string | null): Promise<void> {
  await adminDb()
    .collection('households')
    .doc(householdId)
    .collection('groceryItems')
    .doc(id)
    .set({
      name: 'Milk',
      quantity: null,
      addedBy: 'm-sam',
      addedAt: new Date(),
      boughtAt: null,
      boughtBy: null,
      ...(productId === null
        ? {}
        : {
            productMatch: {
              retailer: 'checkers',
              productId,
              articleCode: '10136729EA',
              unitOfMeasure: 'EA',
              name: 'Milk 2L',
              brand: null,
              priceCents: 3799,
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

describe('linking a Checkers account', () => {
  it('sends a code, verifies it, and reports the link with only four digits', async () => {
    const sam = await signUp();
    expect(await callAs<Status>(sam, 'checkersLinkStatus', {})).toEqual({
      linked: false,
      expiresAt: null,
      mobileMasked: null,
    });
    const sent = await callAs(sam, 'checkersRequestOtp', { mobile: '082 555 1234' });
    expect(sent).toEqual({ sent: true, mobileMasked: '+27 ** *** 1234' });
    const linked = await callAs<Status>(sam, 'checkersVerifyOtp', { code: '123456' });
    expect(linked.linked).toBe(true);
    expect(await callAs<Status>(sam, 'checkersLinkStatus', {})).toEqual(linked);
    const stored = JSON.stringify((await adminDb().doc(`checkersLinks/${sam.uid}`).get()).data());
    expect(stored).not.toContain('5551234');
    expect(stored).not.toContain('emulator-session');
  });

  it('refuses a wrong code, a code nobody asked for, and a number that is not a mobile', async () => {
    const sam = await signUp();
    await expectRefusal(callAs(sam, 'checkersVerifyOtp', { code: '123456' }), 'no-pending-otp');
    await expectRefusal(
      callAs(sam, 'checkersRequestOtp', { mobile: '021 555 1234' }),
      'bad-mobile',
    );
    await callAs(sam, 'checkersRequestOtp', { mobile: '082 555 1234' });
    await expectRefusal(callAs(sam, 'checkersVerifyOtp', { code: '000000' }), 'wrong-code');
  });

  it('refuses a fourth code inside fifteen minutes', async () => {
    const sam = await signUp();
    for (let sent = 0; sent < 3; sent += 1) {
      await callAs(sam, 'checkersRequestOtp', { mobile: '082 555 1234' });
    }
    await expectRefusal(
      callAs(sam, 'checkersRequestOtp', { mobile: '082 555 1234' }),
      'otp-rate-limited',
    );
  });

  it('refuses while the switch is off, and still lets a member unlink', async () => {
    const sam = await signUp();
    await link(sam);
    await adminDb().doc('appConfig/flags').set({ addToCheckers: false });
    await expectRefusal(
      callAs(sam, 'checkersRequestOtp', { mobile: '082 555 1234' }),
      'checkers-switched-off',
    );
    expect(await callAs(sam, 'checkersUnlink', {})).toEqual({ linked: false });
    expect((await adminDb().doc(`checkersLinks/${sam.uid}`).get()).exists).toBe(false);
  });

  it('refuses somebody who is not signed in', async () => {
    await expect(callAs(null, 'checkersLinkStatus', {})).rejects.toThrow(/UNAUTHENTICATED/);
  });
});

describe('filling the cart', () => {
  it('adds the matched items and skips the rest, reading the items itself', async () => {
    const { sam, householdId } = await householdOfTwo();
    await link(sam);
    await anItem(householdId, 'milk', MILK);
    await anItem(householdId, 'typed', null);
    const pushed = await callAs<Pushed>(sam, 'checkersPushToCart', {
      householdId,
      itemIds: ['milk', 'typed', 'nothing'],
    });
    expect(pushed.added.map((line) => line.itemId)).toEqual(['milk']);
    expect(pushed.skipped).toEqual([
      { itemId: 'typed', reason: 'no-match' },
      { itemId: 'nothing', reason: 'not-found' },
    ]);
    expect(pushed.cartItemCount).toBeGreaterThanOrEqual(1);
  });

  it('refuses a member with no link, and a stranger to the household', async () => {
    const { sam, householdId } = await householdOfTwo();
    await anItem(householdId, 'milk', MILK);
    const body = { householdId, itemIds: ['milk'] };
    await expectRefusal(callAs(sam, 'checkersPushToCart', body), 'checkers-link-expired');
    const stranger = await signUp();
    await link(stranger, '083 555 9876');
    await expectRefusal(callAs(stranger, 'checkersPushToCart', body), 'not-a-member');
  });
});
