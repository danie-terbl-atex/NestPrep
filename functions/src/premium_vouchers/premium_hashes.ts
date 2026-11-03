import { hash, subtle, timingSafeEqual } from 'node:crypto';

import { z } from 'zod';

export const MAX_EMAIL_LENGTH = 254;
export const CODE_MIN_LENGTH = 4;
export const CODE_MAX_LENGTH = 20;

const emailShape = z.email();

export function normEmail(raw: string): string | null {
  const email = raw.trim().toLowerCase();
  if (email.length === 0 || email.length > MAX_EMAIL_LENGTH) return null;
  return emailShape.safeParse(email).success ? email : null;
}

export function normCode(raw: string): string | null {
  const code = raw.toUpperCase().replace(/[^A-Z0-9]/g, '');
  return code.length >= CODE_MIN_LENGTH && code.length <= CODE_MAX_LENGTH ? code : null;
}

export function maskEmail(email: string): string {
  const at = email.lastIndexOf('@');
  return `${email.slice(0, 1)}***@${email.slice(at + 1)}`;
}

const utf8 = new TextEncoder();

async function hmacHex(pepper: string, message: string): Promise<string> {
  const key = await subtle.importKey(
    'raw',
    utf8.encode(pepper),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const mac = await subtle.sign('HMAC', key, utf8.encode(message));
  return Buffer.from(mac).toString('hex');
}

export function emailHashOf(pepper: string, email: string): Promise<string> {
  return hmacHex(pepper, `email:${email}`);
}

export function codeHashOf(pepper: string, code: string): Promise<string> {
  return hmacHex(pepper, `code:${code}`);
}

export function otpHashOf(pepper: string, uid: string, code: string): Promise<string> {
  return hmacHex(pepper, `otp:${uid}:${code}`);
}

export function tokenHashOf(token: string): string {
  return hash('sha256', token, 'hex');
}

export function sameHash(a: string, b: string): boolean {
  const left = Buffer.from(a, 'utf8');
  const right = Buffer.from(b, 'utf8');
  return left.length === right.length && timingSafeEqual(left, right);
}

export function includesHash(hashes: readonly string[], candidate: string): boolean {
  let found = false;
  for (const each of hashes) found = sameHash(each, candidate) || found;
  return found;
}
