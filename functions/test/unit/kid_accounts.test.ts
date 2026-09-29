import { Timestamp } from 'firebase-admin/firestore';
import type { HttpsError } from 'firebase-functions/v2/https';
import { describe, expect, it } from 'vitest';

import { KID_CLAIM, carriesKidClaim, kidIdentityOf } from '../../src/accounts/kid_identity';
import { KID_REFUSALS, refuseKid } from '../../src/accounts/kid_errors';
import { parsePairing } from '../../src/accounts/kid_documents';
import { createKidPairingInput, redeemKidPairingInput } from '../../src/accounts/kid_schemas';
import {
  KID_CODE_LENGTH,
  KID_CODE_LIFETIME_MS,
  KID_DEVICE_LIMIT,
  KID_SIGN_IN_ROLES,
  isEligibleForKidSignIn,
  newKidUid,
  pairingRefusal,
} from '../../src/accounts/kid_sign_in_policy';
import { parseInput, requireUid, requireVerifiedUid } from '../../src/household/parse_input';
import {
  READABLE_ALPHABET,
  generateReadableCode,
  isReadableCode,
} from '../../src/shared/readable_code';

/**
 * The rules of kid sign-in, tested where they live (`BE-14`, accounts
 * ADR-0003). The callables are driven end to end in
 * `test/emulator/kid_accounts.test.ts`; this is what those rest on.
 */

const kid = { householdId: 'h1', memberId: 'm-mia' };

describe('a pairing code', () => {
  it('is six readable characters — one breath for a child with a parent beside them', () => {
    const code = generateReadableCode(KID_CODE_LENGTH);
    expect(code).toHaveLength(6);
    expect(code).not.toMatch(/[01OIL]/);
    expect(isReadableCode(code, KID_CODE_LENGTH)).toBe(true);
  });

  it('shares the invite alphabet, so a person learns one set of letters', () => {
    expect(READABLE_ALPHABET).toBe('23456789ABCDEFGHJKMNPQRSTUVWXYZ');
  });

  it('is refused before a read when it could not be one of ours', () => {
    expect(isReadableCode('ABC23', KID_CODE_LENGTH)).toBe(false);
    expect(isReadableCode('ABCD2345', KID_CODE_LENGTH)).toBe(false);
    expect(isReadableCode('ABC10O', KID_CODE_LENGTH)).toBe(false);
  });

  it('lives ten minutes', () => {
    expect(KID_CODE_LIFETIME_MS).toBe(10 * 60 * 1000);
  });

  it('is normalised to upper case, because a child types it however they like', () => {
    expect(parseInput(redeemKidPairingInput, { code: ' abc234 ' }).code).toBe('ABC234');
  });
});

describe('redeeming a pairing', () => {
  const now = Date.parse('2026-09-29T08:00:00Z');
  const pairing = {
    ...kid,
    label: 'Tablet',
    createdBy: 'uid-sam',
    expiresAt: Timestamp.fromMillis(now + 60_000),
  };

  it('is allowed while the code is live', () => {
    expect(pairingRefusal(pairing, now)).toBeNull();
  });

  it('is refused for a code that is not there', () => {
    expect(pairingRefusal(null, now)).toBe('codeNotFound');
  });

  it('is refused the moment the code expires, not a moment after', () => {
    expect(pairingRefusal(pairing, now + 60_000)).toBe('codeExpired');
  });

  it('reads a stored pairing by parsing it, and a malformed one is no pairing', () => {
    expect(parsePairing(pairing)).toEqual(pairing);
    expect(parsePairing({ ...pairing, expiresAt: '2026-09-29' })).toBeNull();
    expect(parsePairing({ householdId: 'h1' })).toBeNull();
    expect(parsePairing(undefined)).toBeNull();
  });
});

describe('who can have a kid sign-in', () => {
  it('an unclaimed member profile', () => {
    expect(isEligibleForKidSignIn({ role: 'member', claimedBy: null })).toBe(true);
  });

  it('not a profile somebody has already claimed', () => {
    expect(isEligibleForKidSignIn({ role: 'member', claimedBy: 'uid-teen' })).toBe(false);
  });

  it('not an admin or a helper, who are not children', () => {
    expect(isEligibleForKidSignIn({ role: 'admin', claimedBy: null })).toBe(false);
    expect(isEligibleForKidSignIn({ role: 'helper', claimedBy: null })).toBe(false);
  });

  it('is one list, so a kid role joins it in one line', () => {
    expect(KID_SIGN_IN_ROLES).toEqual(['member']);
    expect(KID_DEVICE_LIMIT).toBe(5);
  });
});

describe('a kid device uid', () => {
  it('is fresh every time, one per device', () => {
    const uids = new Set(Array.from({ length: 100 }, () => newKidUid()));
    expect(uids.size).toBe(100);
  });

  it('is a valid Auth uid a person can recognise in the console', () => {
    const uid = newKidUid(() => 0);
    expect(uid).toBe(`kid_${'A'.repeat(20)}`);
    expect(uid.length).toBeLessThanOrEqual(128);
  });
});

describe('the kid claim', () => {
  it('names the household and the profile', () => {
    expect(kidIdentityOf({ [KID_CLAIM]: kid })).toEqual(kid);
  });

  it('is absent for every adult', () => {
    expect(kidIdentityOf({ email_verified: true })).toBeNull();
    expect(kidIdentityOf(undefined)).toBeNull();
  });

  it('is parsed, so a claim of the wrong shape is not a kid', () => {
    expect(kidIdentityOf({ [KID_CLAIM]: { householdId: 'h1' } })).toBeNull();
    expect(kidIdentityOf({ [KID_CLAIM]: 'h1/m-mia' })).toBeNull();
  });

  it('but any claim at all is enough to be refused as a kid', () => {
    // Fails closed: something shaped wrongly that calls itself a kid is not
    // let through as an adult.
    expect(carriesKidClaim({ [KID_CLAIM]: 'garbage' })).toBe(true);
    expect(carriesKidClaim({})).toBe(false);
  });
});

describe('a kid device calling a household callable', () => {
  function refusalOf(call: () => unknown): HttpsError {
    try {
      call();
    } catch (error) {
      return error as HttpsError;
    }
    throw new Error('the call should have been refused');
  }

  it('is refused at the door, whatever it asked for', () => {
    const refusal = refusalOf(() => requireUid({ uid: 'kid_x', token: { [KID_CLAIM]: kid } }));
    expect(refusal.code).toBe('permission-denied');
    expect(refusal.details).toEqual({ reason: 'kidAccount' });
  });

  it('including the two that create membership, before the address gate is asked', () => {
    // The kid's token has no address, so without this the refusal would say
    // "verify your email" to a seven-year-old (accounts ADR-0003).
    const refusal = refusalOf(() =>
      requireVerifiedUid({ uid: 'kid_x', token: { [KID_CLAIM]: kid } }),
    );
    expect(refusal.details).toEqual({ reason: 'kidAccount' });
  });

  it('while an adult with no kid claim is let through as before', () => {
    expect(requireUid({ uid: 'uid-sam', token: { email_verified: true } })).toBe('uid-sam');
  });
});

describe('what a kid refusal tells the client', () => {
  it('carries its own reason', () => {
    for (const reason of Object.keys(KID_REFUSALS) as (keyof typeof KID_REFUSALS)[]) {
      expect(refuseKid(reason).details).toEqual({ reason });
    }
  });

  it('a label is optional, trimmed and bounded', () => {
    expect(parseInput(createKidPairingInput, { ...kid }).label).toBe('');
    expect(parseInput(createKidPairingInput, { ...kid, label: '  Tablet ' }).label).toBe('Tablet');
    expect(() => parseInput(createKidPairingInput, { ...kid, label: 'x'.repeat(41) })).toThrow();
  });
});
