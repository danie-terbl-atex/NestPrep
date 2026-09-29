import { hash, hkdfSync, randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';

import { PASS_LIFETIME_MS } from './share_policy';

/**
 * The secrets of a shared link (documents ADR-0006): the token in the link,
 * the PIN, and the short pass a right PIN earns. Nothing here is ever logged
 * or written in the clear.
 */

/** 32 random bytes, base64url: 43 characters with no padding. */
export function newShareToken(): string {
  return randomBytes(32).toString('base64url');
}

export function isShareTokenShape(token: string): boolean {
  return /^[A-Za-z0-9_-]{43}$/.test(token);
}

/** Only this is stored, so the token map holds nothing a leak could use. */
export function hashShareToken(token: string): string {
  return hash('sha256', token, 'hex');
}

export interface PinHash {
  readonly pinHash: string;
  readonly pinSalt: string;
}

export function isPinShape(pin: string): boolean {
  return /^[0-9]{4,8}$/.test(pin);
}

/** scrypt with a salt of its own, so two links with one PIN look unrelated. */
export function hashPin(pin: string, salt: string = randomBytes(16).toString('hex')): PinHash {
  return { pinHash: scryptSync(pin, salt, 32).toString('hex'), pinSalt: salt };
}

export function pinMatches(pin: string, stored: PinHash): boolean {
  if (!isPinShape(pin)) return false;
  const tried = Buffer.from(hashPin(pin, stored.pinSalt).pinHash, 'hex');
  const expected = Buffer.from(stored.pinHash, 'hex');
  return tried.length === expected.length && timingSafeEqual(tried, expected);
}

/**
 * The proof, carried by the file request, that somebody typed the right PIN
 * within the last fifteen minutes. Keyed by the PIN's own hash — a secret only
 * this server holds, and a different one per link — so no global secret has
 * to exist anywhere (HKDF is HMAC underneath).
 */
export function passFor(stored: PinHash, shareId: string, now: Date): string {
  const expiresAt = now.getTime() + PASS_LIFETIME_MS;
  return `${String(expiresAt)}.${signature(stored, shareId, expiresAt)}`;
}

export function passIsValid(pass: string, stored: PinHash, shareId: string, now: Date): boolean {
  const match = /^([0-9]{1,15})\.([A-Za-z0-9_-]{43})$/.exec(pass);
  if (match?.[1] === undefined || match[2] === undefined) return false;
  const expiresAt = Number(match[1]);
  if (expiresAt <= now.getTime() || expiresAt > now.getTime() + PASS_LIFETIME_MS) return false;
  const tried = Buffer.from(match[2]);
  const expected = Buffer.from(signature(stored, shareId, expiresAt));
  return tried.length === expected.length && timingSafeEqual(tried, expected);
}

function signature(stored: PinHash, shareId: string, expiresAt: number): string {
  const key = Buffer.from(stored.pinHash, 'hex');
  const info = `${shareId}.${String(expiresAt)}`;
  return Buffer.from(hkdfSync('sha256', key, stored.pinSalt, info, 32)).toString('base64url');
}
