import { hash, randomBytes } from 'node:crypto';

import { FieldValue, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { z } from 'zod';

import { feedRef, feedTokenRef } from './sync_documents';
import { functionUrl } from './sync_config';

/**
 * The household's feed link (calendar ADR-0003): 32 random bytes, of which
 * only the hash is ever looked up, so the token map holds nothing a leak could
 * use. The link itself is shown to members from `calendarFeed/current`.
 */
export const FEED_FUNCTION_NAME = 'calendarFeed';

export function hashFeedToken(token: string): string {
  return hash('sha256', token, 'hex');
}

export function feedUrlFor(token: string): string {
  return `${functionUrl(FEED_FUNCTION_NAME)}?token=${token}`;
}

const currentShape = z.object({ url: z.string(), tokenHash: z.string() });

export type CurrentFeed = z.infer<typeof currentShape>;

export async function readCurrentFeed(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
): Promise<CurrentFeed | null> {
  const parsed = currentShape.safeParse(
    (await transaction.get(feedRef(store, householdId))).data(),
  );
  return parsed.success ? parsed.data : null;
}

/**
 * Issues a new link inside [transaction], retiring [previous] when there is
 * one — so a reset leaves exactly one working link, never two and never none.
 */
export function issueFeed(
  transaction: Transaction,
  store: Firestore,
  options: { householdId: string; uid: string; previous: CurrentFeed | null },
): string {
  const token = randomBytes(32).toString('base64url');
  const tokenHash = hashFeedToken(token);
  const url = feedUrlFor(token);
  if (options.previous !== null) {
    transaction.delete(feedTokenRef(store, options.previous.tokenHash));
  }
  transaction.set(feedTokenRef(store, tokenHash), {
    householdId: options.householdId,
    createdAt: FieldValue.serverTimestamp(),
  });
  transaction.set(feedRef(store, options.householdId), {
    url,
    tokenHash,
    createdBy: options.uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  return url;
}
