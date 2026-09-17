import { describe, expect, it } from 'vitest';

import {
  INVITE_LIFETIME_MS,
  generateInviteCode,
  looksLikeInviteCode,
} from '../../src/household/invite_code';

describe('an invite code', () => {
  it('is eight characters a person can read off one phone and type into another', () => {
    const code = generateInviteCode();
    expect(code).toHaveLength(8);
    // No 0/O, no 1/I/L — every pair somebody confuses is a support conversation.
    expect(code).not.toMatch(/[01OIL]/);
    expect(looksLikeInviteCode(code)).toBe(true);
  });

  it('draws from the whole alphabet rather than one corner of it', () => {
    const seen = new Set<string>();
    for (let index = 0; index < 200; index += 1) {
      for (const character of generateInviteCode()) seen.add(character);
    }
    expect(seen.size).toBe(31);
  });

  it('is different every time, so one cannot be guessed from the last', () => {
    const codes = new Set(Array.from({ length: 200 }, () => generateInviteCode()));
    expect(codes.size).toBe(200);
  });

  it('uses the randomness it is given, so the test can pin it', () => {
    expect(generateInviteCode(() => 0)).toBe('22222222');
  });

  it('lasts seven days', () => {
    expect(INVITE_LIFETIME_MS).toBe(7 * 24 * 60 * 60 * 1000);
  });
});

describe('recognising a code before looking it up', () => {
  it('rejects anything the wrong length', () => {
    expect(looksLikeInviteCode('')).toBe(false);
    expect(looksLikeInviteCode('ABC2345')).toBe(false);
    expect(looksLikeInviteCode('ABCD23456')).toBe(false);
  });

  it('rejects a character the alphabet deliberately leaves out', () => {
    // A guess that could never have been ours costs the guesser a round trip
    // and costs us no read at all.
    expect(looksLikeInviteCode('O0IL1234')).toBe(false);
    expect(looksLikeInviteCode('abcd2345')).toBe(false);
  });

  it('accepts one we would have issued', () => {
    expect(looksLikeInviteCode('ABCD2345')).toBe(true);
  });
});
