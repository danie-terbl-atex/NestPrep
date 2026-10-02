import type { Firestore } from 'firebase-admin/firestore';

import { consumeRateLimit, type RateLimitRule } from '../shared/rate_limit';

/**
 * How often a login code may be asked for (the Checkers build contract):
 * three per account per fifteen minutes, and — so one account cannot be
 * rotated to flood somebody else's phone — three per number too. Counted in
 * `rateLimits`, where the uid and the number are hashed and never stored.
 */
export const CODES_PER_ACCOUNT: RateLimitRule = {
  name: 'checkersOtpByAccount',
  limit: 3,
  windowSeconds: 15 * 60,
};

export const CODES_PER_NUMBER: RateLimitRule = {
  name: 'checkersOtpByNumber',
  limit: 3,
  windowSeconds: 15 * 60,
};

export async function allowCode(store: Firestore, uid: string, mobile: string): Promise<boolean> {
  if (!(await consumeRateLimit(store, CODES_PER_ACCOUNT, uid))) return false;
  return consumeRateLimit(store, CODES_PER_NUMBER, mobile);
}
