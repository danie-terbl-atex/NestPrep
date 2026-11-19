import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import {
  CallFailed,
  PROJECT_ID,
  callAs,
  clearFirestore,
  closeAdmin,
  signUp,
  signUpUnverified,
} from './emulator_harness';

const AUTH_HOST = process.env['FIREBASE_AUTH_EMULATOR_HOST'] ?? '127.0.0.1:9099';

interface OobCode {
  readonly email: string;
  readonly requestType: string;
}

async function verifyCodesFor(email: string): Promise<OobCode[]> {
  const response = await fetch(`http://${AUTH_HOST}/emulator/v1/projects/${PROJECT_ID}/oobCodes`);
  const { oobCodes } = (await response.json()) as { oobCodes: OobCode[] };
  return oobCodes.filter((code) => code.email === email && code.requestType === 'VERIFY_EMAIL');
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

describe('sendWelcomeEmail', () => {
  it('welcomes a new password account once, with one confirm code', async () => {
    const sam = await signUpUnverified();
    expect(await callAs(sam, 'sendWelcomeEmail', {})).toEqual({ sent: true });
    expect(await verifyCodesFor(sam.email)).toHaveLength(1);

    expect(await callAs(sam, 'sendWelcomeEmail', {})).toEqual({ sent: false });
    expect(await verifyCodesFor(sam.email)).toHaveLength(1);
  });

  it('welcomes an account whose address is already confirmed without making a code', async () => {
    const thandi = await signUp();
    expect(await callAs(thandi, 'sendWelcomeEmail', {})).toEqual({ sent: true });
    expect(await verifyCodesFor(thandi.email)).toHaveLength(0);
  });

  it('refuses a caller who is not signed in', async () => {
    expect(await reasonOf(callAs(null, 'sendWelcomeEmail', {}))).toBe('notSignedIn');
  });
});
