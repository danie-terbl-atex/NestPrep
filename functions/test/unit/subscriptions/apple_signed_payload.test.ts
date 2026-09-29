import { X509Certificate, createHash } from 'node:crypto';

import { describe, expect, it } from 'vitest';

import { appleRootCertificate } from '../../../src/subscriptions/apple/apple_root_certificate';
import {
  SignedPayloadInvalid,
  verifySignedPayload,
} from '../../../src/subscriptions/apple/signed_payload';
import { NOW, TEST_ROOT, appleSigned, appleTransaction } from './store_fixtures';

/**
 * An App Store signature is believed only when its chain ends in a root we
 * trust, every link is signed by the next, the certificates carry Apple's
 * markers and the signature covers exactly what was sent (subscriptions
 * ADR-0001). Each refusal below is a forgery somebody could send.
 */
const trust = { roots: [TEST_ROOT], now: NOW };

function why(run: () => unknown): string {
  try {
    run();
  } catch (error) {
    if (error instanceof SignedPayloadInvalid) return error.why;
    throw error;
  }
  return 'accepted';
}

describe('verifySignedPayload', () => {
  it('returns the payload of a JWS signed along a trusted, marked chain', () => {
    const payload = appleTransaction();
    expect(verifySignedPayload(appleSigned(payload), trust)).toEqual(payload);
  });

  it('refuses a chain that ends in a root nobody trusts — Apple’s root does not vouch for ours', () => {
    const jws = appleSigned(appleTransaction());
    expect(why(() => verifySignedPayload(jws, { roots: [appleRootCertificate()], now: NOW }))).toBe(
      'untrusted root',
    );
  });

  it('refuses a payload changed after it was signed', () => {
    const [header, , signature] = appleSigned(appleTransaction()).split('.');
    const forged = Buffer.from(JSON.stringify(appleTransaction({ productId: 'gift' }))).toString(
      'base64url',
    );
    expect(
      why(() => verifySignedPayload(`${header ?? ''}.${forged}.${signature ?? ''}`, trust)),
    ).toBe('bad signature');
  });

  it('refuses a leaf without the receipt-signing marker, whoever issued it', () => {
    const jws = appleSigned(appleTransaction(), { chain: 'unmarked-leaf' });
    expect(why(() => verifySignedPayload(jws, trust))).toBe('not an App Store signing certificate');
  });

  it('refuses any algorithm but ES256, so "none" cannot be slipped in', () => {
    expect(why(() => verifySignedPayload(appleSigned({}, { alg: 'none' }), trust))).toBe(
      'unexpected header',
    );
  });

  it('refuses a chain checked at a time none of its certificates covers', () => {
    const later = { roots: [TEST_ROOT], now: new Date('2090-01-01T00:00:00Z') };
    expect(why(() => verifySignedPayload(appleSigned({}), later))).toBe('certificate out of date');
  });

  it('refuses something that is not a compact JWS at all', () => {
    expect(why(() => verifySignedPayload('not.a', trust))).toBe('not a compact JWS');
    expect(why(() => verifySignedPayload('a.b.c.d', trust))).toBe('not a compact JWS');
    expect(why(() => verifySignedPayload('x'.repeat(70_000), trust))).toBe('too long');
  });
});

describe('the Apple root NestPrep trusts', () => {
  it('is Apple Root CA - G3, by its published SHA-256 fingerprint', () => {
    const root = appleRootCertificate();
    expect(createHash('sha256').update(root).digest('hex').toUpperCase()).toBe(
      '63343ABFB89A6A03EBB57E9B3F5FA7BE7C4F5C756F3017B3A8C488C3653E9179',
    );
    expect(new X509Certificate(root).subject).toContain('CN=Apple Root CA - G3');
  });
});
