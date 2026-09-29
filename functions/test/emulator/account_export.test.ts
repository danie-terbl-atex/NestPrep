import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import {
  adminBucket,
  adminDb,
  callAs,
  clearFirestore,
  closeAdmin,
  httpFunctionUrl,
} from './emulator_harness';
import {
  addProfile,
  expectRefusal,
  givenSamsDetails,
  household,
  pairKidDevice,
  samsHousehold,
} from './account_data_fixture';

/**
 * Download my data, the web deletion request, and the rate limits on the
 * endpoints anybody can reach (accounts ADR-0006), end to end over HTTP.
 */

beforeEach(clearFirestore);
afterAll(closeAdmin);

interface Exported {
  path: string;
  expiresAt: string;
  fileCount: number;
}

describe('exportAccountData', () => {
  it('writes one JSON of everything about Sam, under Sam’s own prefix, for an hour', async () => {
    const h = await samsHousehold();
    await givenSamsDetails(h);
    await adminDb().collection('storePurchases').doc('p1').set({
      store: 'playStore',
      storeRef: 'purchase-token',
      householdId: h.householdId,
      linkedByUid: h.sam.uid,
      status: 'active',
    });

    const result = await callAs<Exported>(h.sam, 'exportAccountData', null);
    expect(result.path.startsWith(`accountExports/${h.sam.uid}/`)).toBe(true);
    expect(result.fileCount).toBe(1);
    const lifetime = new Date(result.expiresAt).getTime() - Date.now();
    expect(lifetime).toBeGreaterThan(55 * 60 * 1000);
    expect(lifetime).toBeLessThanOrEqual(60 * 60 * 1000);

    const [bytes] = await adminBucket().file(result.path).download();
    const text = bytes.toString('utf8');
    const body = JSON.parse(text) as {
      formatVersion: number;
      signIn: { email: string } | null;
      households: {
        yourRole: string;
        profile: { birthday: string };
        aboutYou: { kind: string }[];
        whatYouAdded: Record<string, unknown>;
      }[];
      vaultFiles: { name: string }[];
      storeSubscriptions: Record<string, unknown>[];
    };
    expect(body.formatVersion).toBe(1);
    expect(body.signIn?.email).toBe(h.sam.email);
    expect(body.households[0]?.yourRole).toBe('admin');
    expect(body.households[0]?.profile.birthday).toBe('1988-04-02');
    expect(body.households[0]?.aboutYou.map((detail) => detail.kind).sort()).toEqual([
      'familyProfiles',
      'memberHealth',
      'memberLocations',
    ]);
    expect(Object.keys(body.households[0]?.whatYouAdded ?? {})).toContain('groceryItems');
    expect(body.vaultFiles.map((file) => file.name)).toEqual(['Passport']);
    expect(body.storeSubscriptions[0]?.['status']).toBe('active');
    // The store's own purchase credential is never handed out, even to its owner.
    expect(text).not.toContain('purchase-token');
  });

  it('keeps only the newest export', async () => {
    const h = await samsHousehold();
    const first = await callAs<Exported>(h.sam, 'exportAccountData', null);
    const second = await callAs<Exported>(h.sam, 'exportAccountData', null);
    const [firstLeft] = await adminBucket().file(first.path).exists();
    const [secondLeft] = await adminBucket().file(second.path).exists();
    expect([firstLeft, secondLeft]).toEqual([false, true]);
  });

  it('refuses a fourth export in the hour', async () => {
    const h = await samsHousehold();
    for (let i = 0; i < 3; i++) await callAs(h.sam, 'exportAccountData', null);
    await expectRefusal(callAs(h.sam, 'exportAccountData', null), 'tooManyRequests');
  });

  it('refuses a kid device and a caller who is not signed in', async () => {
    const h = await samsHousehold();
    const mia = await addProfile(h.householdId, 'Mia', 'kid');
    const tablet = await pairKidDevice(h.sam, h.householdId, mia);
    await expectRefusal(callAs(tablet, 'exportAccountData', null), 'kidAccount');
    await expectRefusal(callAs(null, 'exportAccountData', null), 'notSignedIn');
    expect((await household(h.householdId).get()).exists).toBe(true);
  });
});

async function requestDeletion(
  body: unknown,
  options: { method?: string; from?: string } = {},
): Promise<{ status: number; answer: string | undefined }> {
  const response = await fetch(httpFunctionUrl('requestAccountDeletion'), {
    method: options.method ?? 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Forwarded-For': options.from ?? '198.51.100.1',
    },
    ...(options.method === 'GET' ? {} : { body: JSON.stringify(body) }),
  });
  const parsed = (await response.json().catch(() => ({}))) as { status?: string };
  return { status: response.status, answer: parsed.status };
}

describe('requestAccountDeletion — the public web form', () => {
  it('records a request once per address while it is open, and answers the same either way', async () => {
    const first = await requestDeletion({ email: 'Sam@Example.com', message: 'No app any more' });
    const again = await requestDeletion({ email: 'sam@example.com' });
    expect([first, again]).toEqual([
      { status: 202, answer: 'received' },
      { status: 202, answer: 'received' },
    ]);
    const requests = await adminDb().collection('accountDeletionRequests').get();
    expect(requests.size).toBe(1);
    expect(requests.docs[0]?.get('email')).toBe('sam@example.com');
    expect(requests.docs[0]?.get('status')).toBe('open');
  });

  it('says invalid for a body that is not a request, and refuses any other method', async () => {
    expect(await requestDeletion({ email: 'not an address' })).toEqual({
      status: 400,
      answer: 'invalid',
    });
    expect(await requestDeletion({ email: 'a@b.co', extra: 'x' })).toEqual({
      status: 400,
      answer: 'invalid',
    });
    expect((await requestDeletion(null, { method: 'GET' })).status).toBe(405);
  });

  it('says tooMany after five from one address in an hour', async () => {
    const from = '203.0.113.50';
    for (let i = 0; i < 5; i++) {
      expect((await requestDeletion({ email: `p${String(i)}@example.com` }, { from })).status).toBe(
        202,
      );
    }
    expect(await requestDeletion({ email: 'p6@example.com' }, { from })).toEqual({
      status: 429,
      answer: 'tooMany',
    });
    // Somebody else is not held up by it.
    expect(
      (await requestDeletion({ email: 'q@example.com' }, { from: '203.0.113.51' })).status,
    ).toBe(202);
  });
});

describe('redeemKidPairing — the guard against guessing codes', () => {
  it('refuses the twenty-first attempt from one address in ten minutes, right code or wrong', async () => {
    const url = httpFunctionUrl('redeemKidPairing');
    const attempt = async (): Promise<string | undefined> => {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-Forwarded-For': '192.0.2.77' },
        body: JSON.stringify({ data: { code: 'ZZZZZZ' } }),
      });
      const body = (await response.json()) as { error?: { details?: { reason?: string } } };
      return body.error?.details?.reason;
    };
    for (let i = 0; i < 20; i++) expect(await attempt()).toBe('codeNotFound');
    expect(await attempt()).toBe('tooManyAttempts');
  });
});
