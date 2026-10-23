import { hash, randomBytes } from 'node:crypto';

/** A random value for a URL: `bytes` of randomness, base64url. */
export function randomUrlToken(bytes: number): string {
  return randomBytes(bytes).toString('base64url');
}

/**
 * A PKCE verifier and its S256 challenge (RFC 7636): 32 random bytes give a
 * 43-character verifier, inside the 43–128 the RFC allows.
 */
export function pkcePair(): { verifier: string; challenge: string } {
  const verifier = randomUrlToken(32);
  // One-shot `hash()`: a streaming hash's update call reads as a Firestore
  // write to `writes_are_atomic.test.ts`.
  const challenge = hash('sha256', verifier, 'base64url');
  return { verifier, challenge };
}
