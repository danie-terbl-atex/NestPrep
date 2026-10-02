import { z } from 'zod';

import type { CheckersSession, PendingOtp } from './checkers_api';
import { SealBroken, open, seal } from './session_crypto';

/**
 * The two things a link seals — the pending code and the session — as typed
 * values in and out (ENG-09). A value that does not open, or opens into the
 * wrong shape, is null: it was sealed under a key since rotated, or tampered
 * with, and the caller treats it as never having been there.
 */
const pendingShape = z.object({
  mobile: z.string(),
  reference: z.string(),
  route: z.enum(['bff', 'dsl']),
});

const sessionShape = z.object({
  token: z.string(),
  userId: z.string(),
  uuid: z.string(),
  customerId: z.string(),
});

async function openAs<T extends z.ZodType>(
  schema: T,
  key: Buffer,
  owner: string,
  sealed: string,
): Promise<z.infer<T> | null> {
  let plaintext: string;
  try {
    plaintext = await open(key, owner, sealed);
  } catch (error) {
    if (error instanceof SealBroken) return null;
    throw error;
  }
  let value: unknown;
  try {
    value = JSON.parse(plaintext);
  } catch (error) {
    if (error instanceof SyntaxError) return null;
    throw error;
  }
  const parsed = schema.safeParse(value);
  return parsed.success ? parsed.data : null;
}

export function sealPending(key: Buffer, uid: string, pending: PendingOtp): Promise<string> {
  return seal(key, uid, JSON.stringify(pending));
}

export function openPending(key: Buffer, uid: string, sealed: string): Promise<PendingOtp | null> {
  return openAs(pendingShape, key, uid, sealed);
}

export function sealSession(key: Buffer, uid: string, session: CheckersSession): Promise<string> {
  return seal(key, uid, JSON.stringify(session));
}

export function openSession(
  key: Buffer,
  uid: string,
  sealed: string,
): Promise<CheckersSession | null> {
  return openAs(sessionShape, key, uid, sealed);
}
