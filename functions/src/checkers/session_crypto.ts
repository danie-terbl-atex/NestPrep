import { randomBytes, webcrypto } from 'node:crypto';

/**
 * Sealing what `checkersLinks/{uid}` stores about a member's Checkers account —
 * the session token and the three identifiers behind it, and the pending
 * code's number and reference — with AES-256-GCM under `CHECKERS_SESSION_KEY`
 * (the Checkers build contract, ENG-18).
 *
 * The member's uid is the additional authenticated data, so a sealed value
 * copied onto another member's link does not open. A sealed value is
 * `v1.<iv>.<tag>.<ciphertext>`, each base64url. Web Crypto rather than
 * `createCipheriv`, whose streaming calls read as Firestore writes to
 * `writes_are_atomic.test.ts`.
 */
const VERSION = 'v1';
const KEY_BYTES = 32;
const IV_BYTES = 12;
const TAG_BYTES = 16;

/** Thrown when a sealed value was altered, sealed for somebody else, or under another key. */
export class SealBroken extends Error {
  constructor() {
    super('sealed value does not open');
    this.name = 'SealBroken';
  }
}

/** The key from its configured base64 form, or null when it is not 32 bytes. */
export function sessionKeyFrom(configuredValue: string | null): Buffer | null {
  if (configuredValue === null) return null;
  const key = Buffer.from(configuredValue, 'base64');
  return key.length === KEY_BYTES ? key : null;
}

function aesKey(key: Buffer): Promise<webcrypto.CryptoKey> {
  return webcrypto.subtle.importKey('raw', key, 'AES-GCM', false, ['encrypt', 'decrypt']);
}

function algorithm(iv: Uint8Array, owner: string): webcrypto.AesGcmParams {
  return {
    name: 'AES-GCM',
    iv,
    additionalData: Buffer.from(owner, 'utf8'),
    tagLength: TAG_BYTES * 8,
  };
}

export async function seal(key: Buffer, owner: string, plaintext: string): Promise<string> {
  const iv = randomBytes(IV_BYTES);
  const sealed = Buffer.from(
    await webcrypto.subtle.encrypt(
      algorithm(iv, owner),
      await aesKey(key),
      Buffer.from(plaintext, 'utf8'),
    ),
  );
  const ciphertext = sealed.subarray(0, sealed.length - TAG_BYTES);
  const tag = sealed.subarray(sealed.length - TAG_BYTES);
  return [VERSION, ...[iv, tag, ciphertext].map((part) => part.toString('base64url'))].join('.');
}

export async function open(key: Buffer, owner: string, sealed: string): Promise<string> {
  const [version, iv, tag, ciphertext, ...rest] = sealed.split('.');
  if (version !== VERSION || iv === undefined || tag === undefined || ciphertext === undefined) {
    throw new SealBroken();
  }
  if (rest.length > 0) throw new SealBroken();
  const joined = Buffer.concat([
    Buffer.from(ciphertext, 'base64url'),
    Buffer.from(tag, 'base64url'),
  ]);
  try {
    const plaintext = await webcrypto.subtle.decrypt(
      algorithm(Buffer.from(iv, 'base64url'), owner),
      await aesKey(key),
      joined,
    );
    return Buffer.from(plaintext).toString('utf8');
  } catch (error) {
    // A failed tag, a wrong-length iv: every such failure is the same fact
    // for a caller — this value cannot be trusted.
    if (error instanceof Error) throw new SealBroken();
    throw error;
  }
}
