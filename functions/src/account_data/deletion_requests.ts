import { type Firestore, Timestamp } from 'firebase-admin/firestore';

import type { RateLimitRule } from '../shared/rate_limit';
import type { AccountDeletionRequestInput } from './schemas';

/**
 * Deletion requests made on the public web page, for somebody who no longer
 * has the app (Google Play's data-deletion URL; accounts ADR-0006). The
 * address is the one piece of personal information kept, and only until the
 * request is dealt with: the operator confirms by email that it is the
 * person's, runs the same erasure the app does, and the request is deleted
 * (`functions/tools/deletion-requests.mjs`). Closed to every client.
 */
export const ACCOUNT_DELETION_REQUESTS = 'accountDeletionRequests';

/** Five an hour from one address — somebody retrying, not somebody flooding. */
export const REQUESTS_PER_ADDRESS: RateLimitRule = {
  name: 'accountDeletionRequest:address',
  limit: 5,
  windowSeconds: 60 * 60,
};

/**
 * Two hundred a day from everywhere at once. A forged `x-forwarded-for`
 * defeats the per-address limit; nothing defeats this one, so a flood costs
 * at most this many small writes a day.
 */
export const REQUESTS_PER_DAY: RateLimitRule = {
  name: 'accountDeletionRequest:all',
  limit: 200,
  windowSeconds: 24 * 60 * 60,
};

/**
 * Records a request, once per address while one is open — asking twice is
 * one request. Answering the same whether or not an account exists is
 * deliberate: the form must not tell a stranger who has a NestPrep account.
 */
export async function recordDeletionRequest(
  store: Firestore,
  input: AccountDeletionRequestInput,
  now: Date,
): Promise<'recorded' | 'alreadyOpen'> {
  const requests = store.collection(ACCOUNT_DELETION_REQUESTS);
  return store.runTransaction(async (transaction) => {
    const open = await transaction.get(
      requests.where('email', '==', input.email).where('status', '==', 'open').limit(1),
    );
    if (!open.empty) return 'alreadyOpen';
    transaction.create(requests.doc(), {
      email: input.email,
      message: input.message ?? null,
      status: 'open',
      requestedAt: Timestamp.fromDate(now),
    });
    return 'recorded';
  });
}
