import { hash } from 'node:crypto';

import { type Firestore, Timestamp, type Transaction } from 'firebase-admin/firestore';

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

export interface StagedRateLimit {
  readonly allowed: boolean;
  readonly stage: () => void;
}

export async function readRateLimitIn(
  transaction: Transaction,
  store: Firestore,
  rule: RateLimitRule,
  subject: string,
  now: Date,
): Promise<StagedRateLimit> {
  const ref = store.collection(RATE_LIMITS).doc(rateLimitId(rule, subject));
  const next = nextWindow(readWindow((await transaction.get(ref)).data()), rule, now);
  return {
    allowed: next !== null,
    stage: (): void => {
      if (next === null) return;
      const expiresAt = new Date(next.windowStart.getTime() + rule.windowSeconds * 1000);
      transaction.set(ref, {
        rule: rule.name,
        windowStart: Timestamp.fromDate(next.windowStart),
        count: next.count,
        expiresAt: Timestamp.fromDate(expiresAt),
      });
    },
  };
}

export async function consumeRateLimit(
  store: Firestore,
  rule: RateLimitRule,
  subject: string,
  now: Date = new Date(),
): Promise<boolean> {
  return store.runTransaction(async (transaction) => {
    const limit = await readRateLimitIn(transaction, store, rule, subject, now);
    limit.stage();
    return limit.allowed;
  });
}
