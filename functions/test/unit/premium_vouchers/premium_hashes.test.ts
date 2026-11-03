import { createHmac } from 'node:crypto';

import { describe, expect, it } from 'vitest';

import {
  codeHashOf,
  emailHashOf,
  includesHash,
  maskEmail,
  normCode,
  normEmail,
  otpHashOf,
  sameHash,
  tokenHashOf,
} from '../../../src/premium_vouchers/premium_hashes';

const PEPPER = 'test-pepper';

describe('an email', () => {
  it('is trimmed and lower-cased, and nothing else', () => {
    expect(normEmail('  Sam.Parker+Frames@Gmail.COM ')).toBe('sam.parker+frames@gmail.com');
  });

  it('is refused when it is not an address or is too long', () => {
    expect(normEmail('not an email')).toBeNull();
    expect(normEmail('')).toBeNull();
    expect(normEmail(`${'a'.repeat(250)}@b.co`)).toBeNull();
  });

  it('hashes the same however it was typed, so a limit cannot be dodged by case', async () => {
    const typed = ['Sam@Example.com', ' sam@example.com', 'SAM@EXAMPLE.COM '];
    const hashes = await Promise.all(typed.map((raw) => emailHashOf(PEPPER, normEmail(raw) ?? '')));
    expect(new Set(hashes).size).toBe(1);
  });

  it('is masked to its first letter and its domain', () => {
    expect(maskEmail('sam@gmail.com')).toBe('s***@gmail.com');
    expect(maskEmail('a@b.co')).toBe('a***@b.co');
  });
});

describe('a Premium code', () => {
  it('is upper-cased with every separator removed', () => {
    expect(normCode('abcd-efgh-jkmn')).toBe('ABCDEFGHJKMN');
    expect(normCode(' thandi 30 ')).toBe('THANDI30');
  });

  it('is 4 to 20 letters and numbers', () => {
    expect(normCode('ab-c')).toBeNull();
    expect(normCode('abcd')).toBe('ABCD');
    expect(normCode('x'.repeat(20))).toBe('X'.repeat(20));
    expect(normCode('x'.repeat(21))).toBeNull();
    expect(normCode('----')).toBeNull();
  });
});

describe('the hashes', () => {
  it('are HMAC-SHA256 of a labelled message under the pepper, as hex', async () => {
    const expected = createHmac('sha256', PEPPER).update('email:sam@example.com').digest('hex');
    expect(await emailHashOf(PEPPER, 'sam@example.com')).toBe(expected);
    expect(await codeHashOf(PEPPER, 'THANDI30')).toBe(
      createHmac('sha256', PEPPER).update('code:THANDI30').digest('hex'),
    );
    expect(await otpHashOf(PEPPER, 'uid-1', '123456')).toBe(
      createHmac('sha256', PEPPER).update('otp:uid-1:123456').digest('hex'),
    );
  });

  it('keep an email, a code and a one-time code apart even for the same text', async () => {
    const hashes = await Promise.all([
      emailHashOf(PEPPER, 'ABCD1234'),
      codeHashOf(PEPPER, 'ABCD1234'),
    ]);
    expect(hashes[0]).not.toBe(hashes[1]);
  });

  it('change with the pepper', async () => {
    expect(await emailHashOf('one', 'sam@example.com')).not.toBe(
      await emailHashOf('two', 'sam@example.com'),
    );
  });

  it('hash a gift token with plain SHA-256, as the store does', () => {
    expect(tokenHashOf('abc')).toBe(
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  it('are compared whole, in constant time', () => {
    expect(sameHash('abc', 'abc')).toBe(true);
    expect(sameHash('abc', 'abd')).toBe(false);
    expect(sameHash('abc', 'abcd')).toBe(false);
    expect(includesHash(['a1', 'b2'], 'b2')).toBe(true);
    expect(includesHash(['a1', 'b2'], 'c3')).toBe(false);
    expect(includesHash([], 'c3')).toBe(false);
  });
});
