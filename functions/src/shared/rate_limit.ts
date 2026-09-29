import { hash } from 'node:crypto';

import { type Firestore, Timestamp } from 'firebase-admin/firestore';

/**
 * A fixed-window counter for the endpoints anybody can reach without signing
 * in, and for the expensive ones a signed-in caller could loop (accounts
 * ADR-0006). One document per rule and subject in `rateLimits`, closed to
 * every client by the rules.
 *
 * The subject — an address, a uid — is hashed into the document id and never
 * stored, so the collection holds counts and nothing that names anybody
 * (ENG-22). Each document carries `expiresAt` for a TTL policy to remove.
 */
export const RATE_LIMITS = 'rateLimits';

export interface RateLimitRule {
  /** Stable, because it is part of every document id this rule writes. */
  readonly name: string;
  readonly limit: number;
  readonly windowSeconds: number;
}

export interface RateWindow {
  readonly windowStart: Date;
  readonly count: number;
}

/**
 * The window after one more attempt, or null when the attempt is over the
 * limit. Pure, so the arithmetic is tested without a database.
 */
export function nextWindow(
  existing: RateWindow | null,
  rule: RateLimitRule,
  now: Date,
): RateWindow | null {
  const windowEnds =
    existing === null ? 0 : existing.windowStart.getTime() + rule.windowSeconds * 1000;
  if (existing === null || windowEnds <= now.getTime()) {
    return { windowStart: now, count: 1 };
  }
  if (existing.count >= rule.limit) return null;
  return { windowStart: existing.windowStart, count: existing.count + 1 };
}

export function rateLimitId(rule: RateLimitRule, subject: string): string {
  return hash('sha256', `${rule.name}:${subject}`, 'hex');
}

function readWindow(data: Record<string, unknown> | undefined): RateWindow | null {
  const start = data?.['windowStart'];
  const count = data?.['count'];
  if (!(start instanceof Timestamp) || typeof count !== 'number') return null;
  return { windowStart: start.toDate(), count };
}

/**
 * Counts one attempt against the rule for this subject, in a transaction so
 * two attempts at once cannot both take the last place. True means go ahead.
 */
export async function consumeRateLimit(
  store: Firestore,
  rule: RateLimitRule,
  subject: string,
  now: Date = new Date(),
): Promise<boolean> {
  const ref = store.collection(RATE_LIMITS).doc(rateLimitId(rule, subject));
  return store.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const next = nextWindow(readWindow(snapshot.data()), rule, now);
    if (next === null) return false;
    const expiresAt = new Date(next.windowStart.getTime() + rule.windowSeconds * 1000);
    transaction.set(ref, {
      rule: rule.name,
      windowStart: Timestamp.fromDate(next.windowStart),
      count: next.count,
      expiresAt: Timestamp.fromDate(expiresAt),
    });
    return true;
  });
}
