import { describe, expect, it, vi } from 'vitest';
import { z } from 'zod';

import { UnusableEmail } from '../../../src/premium_vouchers/issue_vouchers';
import {
  type IdTokenCheck,
  bearerOf,
  isStoreCaller,
} from '../../../src/premium_vouchers/store_caller';
import { type StoreRequest, answerStoreCall } from '../../../src/premium_vouchers/store_endpoint';

const STORE = 'nestprep-web@nestprep-web.iam.gserviceaccount.com';
const AUDIENCE = 'https://africa-south1-nestprep-643b7.cloudfunctions.net/issuePremiumVouchers';
const TOKEN = 'eyJhbGciOiJSUzI1NiJ9.eyJlbWFpbCI6InN0b3JlIn0.c2lnbmF0dXJl';

function checkAnswering(
  identity: { email: string | null; emailVerified: boolean } | null,
): IdTokenCheck {
  return vi.fn<IdTokenCheck>(async () => Promise.resolve(identity));
}

const store: IdTokenCheck = checkAnswering({ email: STORE, emailVerified: true });
const schema = z.object({ voucherId: z.string() });
const ok = async (): Promise<Record<string, unknown>> => Promise.resolve({ outcome: 'voided' });

function request(
  overrides: Partial<{ method: string; authorization: string; body: unknown }> = {},
): StoreRequest {
  return {
    method: overrides.method ?? 'POST',
    headers: { authorization: overrides.authorization ?? `Bearer ${TOKEN}` },
    body: 'body' in overrides ? overrides.body : { voucherId: 'ord_1_1' },
  };
}

describe('who may call the store endpoints', () => {
  it('reads a bearer token and nothing else', () => {
    expect(bearerOf(`Bearer ${TOKEN}`)).toBe(TOKEN);
    expect(bearerOf(`bearer ${TOKEN}`)).toBeNull();
    expect(bearerOf(TOKEN)).toBeNull();
    expect(bearerOf(undefined)).toBeNull();
    expect(bearerOf(['Bearer a', 'Bearer b'])).toBeNull();
    expect(bearerOf('Bearer short')).toBeNull();
  });

  it('is the store’s service account, with a verified email, checked against the function’s URL', async () => {
    const check = checkAnswering({ email: STORE, emailVerified: true });
    expect(await isStoreCaller(check, `Bearer ${TOKEN}`, AUDIENCE, STORE)).toBe(true);
    expect(check).toHaveBeenCalledWith(TOKEN, AUDIENCE);
    expect(
      await isStoreCaller(
        checkAnswering({ email: STORE.toUpperCase(), emailVerified: true }),
        `Bearer ${TOKEN}`,
        AUDIENCE,
        STORE,
      ),
    ).toBe(true);
  });

  it.each([
    [
      'another service account',
      { email: 'someone@else.iam.gserviceaccount.com', emailVerified: true },
    ],
    ['an unverified email', { email: STORE, emailVerified: false }],
    ['no email claim', { email: null, emailVerified: true }],
    ['a token that does not verify', null],
  ])('is not %s', async (_, identity) => {
    expect(await isStoreCaller(checkAnswering(identity), `Bearer ${TOKEN}`, AUDIENCE, STORE)).toBe(
      false,
    );
  });

  it('is nobody while the service account is not configured', async () => {
    const check = checkAnswering({ email: STORE, emailVerified: true });
    expect(await isStoreCaller(check, `Bearer ${TOKEN}`, AUDIENCE, null)).toBe(false);
    expect(check).not.toHaveBeenCalled();
  });
});

describe('a store call', () => {
  const deps = { check: store, audience: AUDIENCE, invokerEmail: STORE };

  it('answers 200 with what the endpoint said', async () => {
    expect(await answerStoreCall(deps, request(), schema, ok)).toEqual({
      status: 200,
      body: { outcome: 'voided' },
    });
  });

  it('is POST only', async () => {
    expect((await answerStoreCall(deps, request({ method: 'GET' }), schema, ok)).status).toBe(405);
  });

  it('is refused 403 before its body is read when the caller is not the store', async () => {
    const answer = vi.fn(ok);
    const reply = await answerStoreCall(
      { ...deps, check: checkAnswering(null) },
      request({ body: 'garbage' }),
      schema,
      answer,
    );
    expect(reply).toEqual({ status: 403, body: { error: 'forbidden' } });
    expect(answer).not.toHaveBeenCalled();
    const unset = await answerStoreCall({ ...deps, invokerEmail: null }, request(), schema, ok);
    expect(unset.status).toBe(403);
  });

  it('answers 400 badRequest to any bad shape', async () => {
    for (const body of [null, 'x', {}, { voucherId: 5 }]) {
      expect(await answerStoreCall(deps, request({ body }), schema, ok)).toEqual({
        status: 400,
        body: { error: 'badRequest' },
      });
    }
  });

  it('answers 400 badRequest to an email that is not an address', async () => {
    const reply = await answerStoreCall(deps, request(), schema, async () => {
      await Promise.resolve();
      throw new UnusableEmail();
    });
    expect(reply).toEqual({ status: 400, body: { error: 'badRequest' } });
  });

  it('lets anything else fail loudly, for the transport to answer 500', async () => {
    await expect(
      answerStoreCall(deps, request(), schema, async () => {
        await Promise.resolve();
        throw new Error('firestore down');
      }),
    ).rejects.toThrow('firestore down');
  });
});
