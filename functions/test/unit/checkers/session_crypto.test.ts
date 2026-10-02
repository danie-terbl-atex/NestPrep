import { randomBytes } from 'node:crypto';

import { describe, expect, it } from 'vitest';

import { SealBroken, open, seal, sessionKeyFrom } from '../../../src/checkers/session_crypto';

/**
 * AES-256-GCM sealing of what a Checkers link stores (the Checkers build
 * contract, ENG-18): what goes in comes out, for its owner, under its key —
 * and nothing else opens it.
 */

const KEY = randomBytes(32);

describe('a sealed value', () => {
  it('opens back to what was sealed', async () => {
    const sealed = await seal(KEY, 'uid-sam', '{"token":"abc"}');
    expect(await open(KEY, 'uid-sam', sealed)).toBe('{"token":"abc"}');
  });

  it('does not carry what it seals in the clear, and differs every time', async () => {
    const first = await seal(KEY, 'uid-sam', 'session-token-123');
    const second = await seal(KEY, 'uid-sam', 'session-token-123');
    expect(first).not.toContain('session-token');
    expect(first).not.toBe(second);
    expect(first.startsWith('v1.')).toBe(true);
  });

  it('does not open for another member', async () => {
    const sealed = await seal(KEY, 'uid-sam', 'secret');
    await expect(open(KEY, 'uid-thandi', sealed)).rejects.toThrow(SealBroken);
  });

  it('does not open under another key', async () => {
    const sealed = await seal(KEY, 'uid-sam', 'secret');
    await expect(open(randomBytes(32), 'uid-sam', sealed)).rejects.toThrow(SealBroken);
  });

  it('does not open once altered', async () => {
    const sealed = await seal(KEY, 'uid-sam', 'secret');
    const parts = sealed.split('.');
    const body = Buffer.from(parts[3] ?? '', 'base64url');
    body[0] = (body[0] ?? 0) ^ 1;
    parts[3] = body.toString('base64url');
    await expect(open(KEY, 'uid-sam', parts.join('.'))).rejects.toThrow(SealBroken);
  });

  it.each([['not sealed at all'], ['v2.a.b.c'], ['v1.a.b'], ['v1.a.b.c.d']])(
    'refuses %s',
    async (value) => {
      await expect(open(KEY, 'uid-sam', value)).rejects.toThrow(SealBroken);
    },
  );
});

describe('the session key', () => {
  it('is 32 bytes of base64', () => {
    expect(sessionKeyFrom(KEY.toString('base64'))?.equals(KEY)).toBe(true);
  });

  it('is no key when it is missing or the wrong length', () => {
    expect(sessionKeyFrom(null)).toBeNull();
    expect(sessionKeyFrom(randomBytes(16).toString('base64'))).toBeNull();
  });
});
