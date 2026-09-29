import { describe, expect, it } from 'vitest';

import {
  MAX_PIN_ATTEMPTS,
  PASS_LIFETIME_MS,
  attemptsLeft,
  expiryFor,
  mayShare,
  purgeAfter,
  verdictFor,
  type ShareState,
} from '../../src/documents/share/share_policy';
import {
  hashPin,
  hashShareToken,
  isPinShape,
  isShareTokenShape,
  newShareToken,
  passFor,
  passIsValid,
  pinMatches,
} from '../../src/documents/share/share_secrets';

/**
 * The rules of a shared link (documents ADR-0006), without an emulator: who
 * may share, when a link stops working, and the secrets that guard it.
 */

const NOW = new Date('2026-09-29T10:00:00Z');
const HOUR = 60 * 60 * 1000;

describe('who may share a document outside the household', () => {
  it('the family may share anything — a household paper or any vault', () => {
    for (const role of ['admin', 'parent', 'member']) {
      expect(mayShare({ role, memberId: 'm-sam' }, 'household', null), role).toBe(true);
      expect(mayShare({ role, memberId: 'm-sam' }, 'vault', 'm-emma'), role).toBe(true);
    }
  });

  it("a vault's owner may share their own vault, whatever their role", () => {
    expect(mayShare({ role: 'helper', memberId: 'm-thandi' }, 'vault', 'm-thandi')).toBe(true);
  });

  it("nobody else may share somebody else's vault, even with a grant to read it", () => {
    expect(mayShare({ role: 'helper', memberId: 'm-thandi' }, 'vault', 'm-emma')).toBe(false);
    expect(mayShare({ role: 'carer', memberId: undefined }, 'vault', 'm-emma')).toBe(false);
  });

  it('a helper does not send the household papers out, even with documents: edit', () => {
    expect(mayShare({ role: 'helper', memberId: 'm-thandi' }, 'household', null)).toBe(false);
    expect(mayShare({ role: 'kid', memberId: 'm-kid' }, 'household', null)).toBe(false);
  });

  it('somebody not in the household may share nothing', () => {
    expect(mayShare({ role: undefined, memberId: undefined }, 'vault', 'm-emma')).toBe(false);
  });
});

describe('when a link stops working', () => {
  it('a chosen lifetime ends that many hours after it was made', () => {
    expect(expiryFor(NOW, { kind: 'hours', hours: 4 }).getTime()).toBe(NOW.getTime() + 4 * HOUR);
  });

  it('a shift-bound link is never longer than seven days, even if the shift is never ended', () => {
    expect(expiryFor(NOW, { kind: 'shift', shiftId: 's1' }).getTime()).toBe(
      NOW.getTime() + 168 * HOUR,
    );
  });

  it('its record is kept for thirty days after that, then purged', () => {
    const ends = expiryFor(NOW, { kind: 'hours', hours: 1 });
    expect(purgeAfter(ends).getTime() - ends.getTime()).toBe(30 * 24 * HOUR);
  });

  const live: ShareState = {
    status: 'active',
    expiresAt: new Date(NOW.getTime() + HOUR),
    shiftIsOpen: true,
    featureIsOn: true,
    creatorMayShare: true,
    documentExists: true,
  };

  it('opens while every check holds', () => {
    expect(verdictFor(live, NOW)).toBe('open');
  });

  it('says expired at and after its end — the one reason worth telling apart', () => {
    expect(verdictFor({ ...live, expiresAt: NOW }, NOW)).toBe('expired');
    expect(verdictFor({ ...live, expiresAt: new Date(NOW.getTime() - 1) }, NOW)).toBe('expired');
  });

  it('says ended for every other reason: stopped, shift over, switched off, creator removed, document gone', () => {
    expect(verdictFor({ ...live, status: 'revoked' }, NOW)).toBe('ended');
    expect(verdictFor({ ...live, status: 'ended' }, NOW)).toBe('ended');
    expect(verdictFor({ ...live, shiftIsOpen: false }, NOW)).toBe('ended');
    expect(verdictFor({ ...live, featureIsOn: false }, NOW)).toBe('ended');
    expect(verdictFor({ ...live, creatorMayShare: false }, NOW)).toBe('ended');
    expect(verdictFor({ ...live, documentExists: false }, NOW)).toBe('ended');
  });

  it('a stopped link says ended even after it would have expired', () => {
    expect(verdictFor({ ...live, status: 'revoked', expiresAt: NOW }, NOW)).toBe('ended');
  });
});

describe('the PIN limit', () => {
  it('is five, and counts down to zero, never below', () => {
    expect(MAX_PIN_ATTEMPTS).toBe(5);
    expect(attemptsLeft(0)).toBe(5);
    expect(attemptsLeft(4)).toBe(1);
    expect(attemptsLeft(9)).toBe(0);
  });
});

describe('the token', () => {
  it('is 32 random bytes as 43 base64url characters, different every time', () => {
    const one = newShareToken();
    expect(isShareTokenShape(one)).toBe(true);
    expect(one).not.toBe(newShareToken());
  });

  it('is stored only as its hash', () => {
    const token = newShareToken();
    expect(hashShareToken(token)).toMatch(/^[0-9a-f]{64}$/);
    expect(hashShareToken(token)).not.toContain(token);
  });

  it('refuses anything that is not that shape before a lookup', () => {
    for (const bad of ['', 'short', `${newShareToken()}x`, '../'.repeat(15), 'a b'.repeat(15)]) {
      expect(isShareTokenShape(bad), bad).toBe(false);
    }
  });
});

describe('the PIN', () => {
  it('is 4 to 8 digits', () => {
    expect(isPinShape('1234')).toBe(true);
    expect(isPinShape('12345678')).toBe(true);
    for (const bad of ['123', '123456789', '12a4', ' 1234', '']) {
      expect(isPinShape(bad), bad).toBe(false);
    }
  });

  it('is kept as a salted hash that the right PIN matches and a wrong one does not', () => {
    const stored = hashPin('2468');
    expect(stored.pinHash).not.toContain('2468');
    expect(pinMatches('2468', stored)).toBe(true);
    expect(pinMatches('2469', stored)).toBe(false);
    expect(pinMatches('not a pin', stored)).toBe(false);
  });

  it('hashes one PIN differently for two links', () => {
    expect(hashPin('2468').pinHash).not.toBe(hashPin('2468').pinHash);
  });
});

describe('the pass a right PIN earns', () => {
  const pin = hashPin('2468');

  it('opens the file for fifteen minutes, for that link only', () => {
    const pass = passFor(pin, 'share-1', NOW);
    expect(passIsValid(pass, pin, 'share-1', NOW)).toBe(true);
    expect(passIsValid(pass, pin, 'share-1', new Date(NOW.getTime() + PASS_LIFETIME_MS - 1))).toBe(
      true,
    );
    expect(passIsValid(pass, pin, 'share-1', new Date(NOW.getTime() + PASS_LIFETIME_MS))).toBe(
      false,
    );
    expect(passIsValid(pass, pin, 'share-2', NOW)).toBe(false);
  });

  it('is refused under another link, another PIN, or with its time pushed later', () => {
    const pass = passFor(pin, 'share-1', NOW);
    expect(passIsValid(pass, hashPin('2468'), 'share-1', NOW)).toBe(false);
    const [expires, signature] = pass.split('.');
    const later = `${String(Number(expires) + 60_000)}.${signature ?? ''}`;
    expect(passIsValid(later, pin, 'share-1', NOW)).toBe(false);
  });

  it('is refused when it is not a pass at all', () => {
    for (const bad of ['', 'x', '123.abc', `${String(NOW.getTime())}.`]) {
      expect(passIsValid(bad, pin, 'share-1', NOW), bad).toBe(false);
    }
  });
});
