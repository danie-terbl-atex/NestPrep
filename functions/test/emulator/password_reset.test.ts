import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { PASSWORD_RESETS_PER_EMAIL } from '../../src/accounts/password_reset';
import {
  CallFailed,
  PROJECT_ID,
  callAs,
  clearFirestore,
  closeAdmin,
  signUp,
} from './emulator_harness';

const AUTH_HOST = process.env['FIREBASE_AUTH_EMULATOR_HOST'] ?? '127.0.0.1:9099';

interface OobCode {
  readonly email: string;
  readonly requestType: string;
  readonly oobCode: string;
}

async function resetCodesFor(email: string): Promise<OobCode[]> {
  const response = await fetch(`http://${AUTH_HOST}/emulator/v1/projects/${PROJECT_ID}/oobCodes`);
  const { oobCodes } = (await response.json()) as { oobCodes: OobCode[] };
  return oobCodes.filter((code) => code.email === email && code.requestType === 'PASSWORD_RESET');
}

async function reasonOf(promise: Promise<unknown>): Promise<string | undefined> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof CallFailed) return error.reason;
    throw error;
  }
  return 'resolved';
}

beforeEach(clearFirestore);
afterAll(closeAdmin);

describe('sendPasswordReset', () => {
  it('makes a reset code for an account, signed out, and answers sent', async () => {
    const sam = await signUp();
    const answer = await callAs(null, 'sendPasswordReset', {
      email: ` ${sam.email.toUpperCase()} `,
    });
    expect(answer).toEqual({ sent: true });
    expect(await resetCodesFor(sam.email)).toHaveLength(1);
  });

  it('answers sent for an address with no account, so nobody learns who has one', async () => {
    const answer = await callAs(null, 'sendPasswordReset', { email: 'nobody@nestprep.test' });
    expect(answer).toEqual({ sent: true });
    expect(await resetCodesFor('nobody@nestprep.test')).toHaveLength(0);
  });

  it('refuses something that is not an address', async () => {
    expect(await reasonOf(callAs(null, 'sendPasswordReset', { email: 'sam' }))).toBe('badRequest');
  });

  it(`refuses tooManyAttempts past ${String(PASSWORD_RESETS_PER_EMAIL.limit)} for one address`, async () => {
    const sam = await signUp();
    for (let sent = 0; sent < PASSWORD_RESETS_PER_EMAIL.limit; sent += 1) {
      await callAs(null, 'sendPasswordReset', { email: sam.email });
    }
    expect(await reasonOf(callAs(null, 'sendPasswordReset', { email: sam.email }))).toBe(
      'tooManyAttempts',
    );
    expect(await resetCodesFor(sam.email)).toHaveLength(PASSWORD_RESETS_PER_EMAIL.limit);
  });
});
