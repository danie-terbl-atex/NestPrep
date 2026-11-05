import type { DocumentReference } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { monthKeyIn } from '../../src/ai/usage_rules';
import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { adminDb, callAs, clearFirestore, signUp, type TestUser } from './emulator_harness';

/**
 * `readShoppingList` end to end, over HTTP with a real token (list-scan
 * ADR-0001, foundation ADR-0015). The emulator's model answers from
 * `aiEmulator/listScan`; the flag, the grant, premium, the photo check, the
 * cap and the ledger are the real code path.
 */

const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]).toString('base64');
const PNG_BYTES_AS_JPEG = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]).toString(
  'base64',
);
const MONTH = monthKeyIn('Africa/Johannesburg', new Date());

interface Home {
  readonly sam: TestUser;
  readonly thandi: TestUser;
  readonly householdId: string;
}

const home = (householdId: string): DocumentReference =>
  adminDb().collection('households').doc(householdId);

async function premium(householdId: string): Promise<void> {
  await home(householdId)
    .collection('entitlement')
    .doc('current')
    .set({ premiumUntil: new Date(Date.now() + 86_400_000) });
}

/** Sam the admin and Thandi, a helper on the defaults (groceries: edit), with premium. */
async function aPremiumHousehold(thandiRole = 'helper'): Promise<Home> {
  const household = await householdOfTwo(thandiRole);
  await premium(household.householdId);
  return household;
}

async function modelAnswers(reply: unknown): Promise<void> {
  await adminDb()
    .collection('aiEmulator')
    .doc('listScan')
    .set({ reply: JSON.stringify(reply) });
}

const photoOf = (householdId: string, data = JPEG): Record<string, string> => ({
  householdId,
  mimeType: 'image/jpeg',
  data,
});

beforeEach(async () => {
  await clearFirestore();
});

describe('a premium household snapping a list', () => {
  it('gets the lines back, tidied and once each, and nothing on the list', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await modelAnswers({
      items: [
        { name: 'Milk', quantity: '2 l' },
        { name: ' Brown  bread ', quantity: null },
        { name: 'milk' },
      ],
    });
    const result = await callAs<{ lines: unknown[]; callsLeft: number }>(
      sam,
      'readShoppingList',
      photoOf(householdId),
    );
    expect(result.lines).toEqual([
      { name: 'Milk', quantity: '2 l' },
      { name: 'Brown bread', quantity: null },
    ]);
    expect(result.callsLeft).toBe(99);
    expect((await home(householdId).collection('groceryItems').get()).size).toBe(0);
  });

  it('is counted under its own feature, with a line that names no item', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await modelAnswers({ items: [{ name: 'Rooibos' }] });
    await callAs(sam, 'readShoppingList', photoOf(householdId));
    const month = await home(householdId).collection('aiUsage').doc(MONTH).get();
    expect(month.data()).toMatchObject({ calls: 1, byFeature: { listScan: 1 } });
    const lines = await month.ref.collection('calls').get();
    expect(JSON.stringify(lines.docs.map((line) => line.data()))).not.toContain('Rooibos');
  });

  it('a helper who may add to the list may snap one too', async () => {
    const { thandi, householdId } = await aPremiumHousehold();
    await modelAnswers({ items: [] });
    const result = await callAs<{ lines: unknown[] }>(
      thandi,
      'readShoppingList',
      photoOf(householdId),
    );
    expect(result.lines).toEqual([]);
  });

  it('refunds a call the model failed', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await adminDb().collection('aiEmulator').doc('listScan').set({ failWith: 'permanent' });
    await expectRefusal(callAs(sam, 'readShoppingList', photoOf(householdId)), 'aiUnavailable');
    const month = await home(householdId).collection('aiUsage').doc(MONTH).get();
    expect(month.data()).toMatchObject({ calls: 0, attempts: 1 });
  });
});

describe('who may, and what', () => {
  it('a free household meets the paywall on this feature, before a call is counted', async () => {
    const { sam, householdId } = await householdOfTwo('helper');
    await modelAnswers({ items: [] });
    await expectRefusal(callAs(sam, 'readShoppingList', photoOf(householdId)), 'premiumRequired');
    expect((await home(householdId).collection('aiUsage').doc(MONTH).get()).exists).toBe(false);
  });

  it('a carer who may only see the list is refused', async () => {
    const { thandi, householdId } = await aPremiumHousehold('carer');
    await expectRefusal(
      callAs(thandi, 'readShoppingList', photoOf(householdId)),
      'groceriesNotShared',
    );
  });

  it('somebody from another household is refused', async () => {
    const { householdId } = await aPremiumHousehold();
    const stranger = await signUp();
    await expectRefusal(callAs(stranger, 'readShoppingList', photoOf(householdId)), 'notAMember');
  });

  it('a file that is not what it claims is refused before a call is counted', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await expectRefusal(
      callAs(sam, 'readShoppingList', photoOf(householdId, PNG_BYTES_AS_JPEG)),
      'listPhotoNotSupported',
    );
    expect((await home(householdId).collection('aiUsage').doc(MONTH).get()).exists).toBe(false);
  });

  it('the V2 flag refuses when it is set off', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await adminDb().collection('appConfig').doc('flags').set({ snapShoppingList: false });
    await expectRefusal(callAs(sam, 'readShoppingList', photoOf(householdId)), 'listScanOff');
  });

  it('the AI feature switch refuses before anything is counted', async () => {
    const { sam, householdId } = await aPremiumHousehold();
    await adminDb()
      .collection('appConfig')
      .doc('ai')
      .set({ features: { listScan: false } });
    await expectRefusal(callAs(sam, 'readShoppingList', photoOf(householdId)), 'aiSwitchedOff');
    expect((await home(householdId).collection('aiUsage').doc(MONTH).get()).exists).toBe(false);
  });
});
