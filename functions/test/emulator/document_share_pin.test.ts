import { beforeEach, describe, expect, it } from 'vitest';

import { adminDb, clearFirestore } from './emulator_harness';
import {
  CARD_BYTES,
  fileQueryIn,
  givenSharingParkers,
  open,
  share,
  shareDoc,
  submitPin,
  tokenOf,
  type SharingParkers,
} from './document_share_fixture';

/**
 * A shared link with a PIN, end to end (documents ADR-0006): nothing is named
 * before the PIN, a right PIN earns a short pass the file request must carry,
 * a forged pass opens nothing, and the fifth wrong PIN locks the link for
 * good — even against the right one afterwards.
 */

let parkers: SharingParkers;

beforeEach(async () => {
  await clearFirestore();
  parkers = await givenSharingParkers();
});

async function vaultViews(ownerMemberId: string): Promise<Record<string, unknown>[]> {
  const views = await adminDb()
    .collection(`households/${parkers.householdId}/vaults/${ownerMemberId}/views`)
    .get();
  return views.docs.map((view) => view.data());
}

describe('a link with a PIN', () => {
  it('asks for the PIN before naming anything, and a right PIN opens it', async () => {
    const made = await share(parkers.sam, parkers.householdId, { pin: '2468' });
    const token = tokenOf(made.url);
    const asked = await (await open(token)).text();
    expect(asked).toContain('Enter the PIN');
    expect(asked).not.toContain('Emma medical aid card');

    // Without the pass a right PIN earns, the file is the form again.
    const noPass = await open(token, '&file=1');
    expect(noPass.headers.get('content-type')).toContain('text/html');
    expect(await vaultViews('m-emma')).toHaveLength(0);

    const page = await (await submitPin(token, '2468')).text();
    expect(page).toContain('Emma medical aid card');
    const file = await open(token, fileQueryIn(page));
    expect(Buffer.from(await file.arrayBuffer())).toEqual(CARD_BYTES);
    expect(await vaultViews('m-emma')).toHaveLength(1);
  });

  it('a forged pass does not open the file', async () => {
    const made = await share(parkers.sam, parkers.householdId, { pin: '2468' });
    const forged = `&file=1&p=${String(Date.now() + 60_000)}.${'A'.repeat(43)}`;
    const response = await open(tokenOf(made.url), forged);
    expect(response.headers.get('content-type')).toContain('text/html');
    expect(await vaultViews('m-emma')).toHaveLength(0);
  });

  it('locks for good on the fifth wrong PIN, even against the right one after', async () => {
    const made = await share(parkers.sam, parkers.householdId, { pin: '2468' });
    const token = tokenOf(made.url);
    for (const left of [4, 3, 2, 1]) {
      const html = await (await submitPin(token, '1111')).text();
      expect(html).toContain(left === 1 ? 'one try left' : `${String(left)} tries left`);
    }
    // Letters are not a guess and cost nothing.
    expect(await (await submitPin(token, 'abcd')).text()).toContain('one try left');

    const fifth = await submitPin(token, '1111');
    expect(fifth.status).toBe(410);
    expect(await fifth.text()).toContain('This link is locked');
    expect(await shareDoc(parkers.householdId, made.shareId)).toMatchObject({ status: 'locked' });

    const right = await submitPin(token, '2468');
    expect(right.status).toBe(410);
    expect(await vaultViews('m-emma')).toHaveLength(0);
  });
});
