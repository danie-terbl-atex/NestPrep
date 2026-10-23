import { z } from 'zod';

import { openJson, sealJson } from '../shared/sealed_json';
import type { CheckersSession, PendingOtp } from './checkers_api';

/**
 * The two things a Checkers link seals — the pending code and the session —
 * as typed values in and out (ENG-09). A value that does not open is null.
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

export function sealPending(key: Buffer, uid: string, pending: PendingOtp): Promise<string> {
  return sealJson(key, uid, pending);
}

export function openPending(key: Buffer, uid: string, sealed: string): Promise<PendingOtp | null> {
  return openJson(pendingShape, key, uid, sealed);
}

export function sealSession(key: Buffer, uid: string, session: CheckersSession): Promise<string> {
  return sealJson(key, uid, session);
}

export function openSession(
  key: Buffer,
  uid: string,
  sealed: string,
): Promise<CheckersSession | null> {
  return openJson(sessionShape, key, uid, sealed);
}
