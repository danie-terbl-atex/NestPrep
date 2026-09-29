import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { loadRoster, recipientIn } from './household_roster';
import { MAX_PUSH_ATTEMPTS, storedInboxItem, type StoredInboxItem } from './inbox_item';
import { TOKENS_PER_ACCOUNT, inboxRef, pushTokensOf } from './notification_refs';
import type { PushSender } from './push_sender';

/**
 * Sends one inbox item's push (notifications ADR-0001).
 *
 * **At most once.** The item is claimed — its push marked `sent` — in a
 * transaction *before* anything is sent, so two runs that meet on the same
 * item send it once between them. A crash between the claim and the send
 * loses that buzz and nothing else: the inbox still holds the notification.
 * A duplicate buzz on a family's phones is the worse failure of the two.
 *
 * Then it reads who the item is for *now* — somebody who left the household
 * since is nobody's recipient — and their phones, sends, forgets the tokens
 * FCM says are dead, and records what happened. An outage puts the push back
 * five minutes later, three tries in all; then the inbox is all it gets.
 */
export type DispatchResult = 'sent' | 'noDevice' | 'failed' | 'retry' | 'notDue' | 'gone';

export const RETRY_AFTER_MS = 5 * 60 * 1000;

async function claim(
  store: Firestore,
  householdId: string,
  itemId: string,
  now: Date,
): Promise<StoredInboxItem | undefined> {
  const ref = inboxRef(store, householdId, itemId);
  return store.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const item = storedInboxItem.safeParse(snapshot.data());
    if (!snapshot.exists || !item.success) return undefined;
    if (item.data.push.state !== 'pending') return undefined;
    if (item.data.push.sendAfter.toMillis() > now.getTime()) return undefined;
    transaction.update(ref, {
      'push.state': 'sent',
      'push.attempts': item.data.push.attempts + 1,
    });
    return item.data;
  });
}

/** Every phone signed in as [uids]: token → the account that registered it. */
async function tokensOf(
  store: Firestore,
  uids: readonly string[],
): Promise<Record<string, string>> {
  const reads = await Promise.all(
    uids.map((uid) => pushTokensOf(store, uid).limit(TOKENS_PER_ACCOUNT).get()),
  );
  return Object.fromEntries(
    reads.flatMap((snapshot, index) => {
      const uid = uids[index];
      return uid === undefined ? [] : snapshot.docs.map((doc) => [doc.id, uid] as const);
    }),
  );
}

export interface DispatchOptions {
  readonly store: Firestore;
  readonly sender: PushSender;
  readonly householdId: string;
  readonly itemId: string;
  readonly now: Date;
}

export async function dispatchInboxItem(options: DispatchOptions): Promise<DispatchResult> {
  const { store, sender, householdId, itemId, now } = options;
  const item = await claim(store, householdId, itemId, now);
  if (item === undefined) return 'notDue';
  const ref = inboxRef(store, householdId, itemId);

  const roster = await loadRoster(store, householdId);
  const recipient = roster === null ? undefined : recipientIn(roster, item.memberId);
  const owners = recipient === undefined ? {} : await tokensOf(store, recipient.uids);
  const tokens = Object.keys(owners);
  if (tokens.length === 0) {
    const batch = store.batch();
    batch.update(ref, { 'push.state': 'noDevice' });
    await batch.commit();
    return recipient === undefined ? 'gone' : 'noDevice';
  }

  const outcome = await sender.send({
    tokens,
    category: item.category,
    title: item.title,
    body: item.body,
    data: {
      householdId,
      inboxId: itemId,
      target: item.target.kind,
      targetId: item.target.id ?? '',
    },
  });

  const result = settle(item, outcome.delivered, outcome.retryable);
  // The dead tokens are forgotten with the outcome, in one write (BE-07).
  const batch = store.batch();
  for (const token of outcome.invalidTokens) {
    const uid = owners[token];
    if (uid !== undefined) batch.delete(pushTokensOf(store, uid).doc(token));
  }
  batch.update(ref, pushUpdate(result, outcome.delivered, now));
  await batch.commit();
  logger.info('push dispatched', {
    householdId,
    itemId,
    category: item.category,
    result,
    devices: tokens.length,
    delivered: outcome.delivered,
    forgotten: outcome.invalidTokens.length,
  });
  return result;
}

function settle(item: StoredInboxItem, delivered: number, retryable: boolean): DispatchResult {
  if (delivered > 0) return 'sent';
  if (retryable && item.push.attempts + 1 < MAX_PUSH_ATTEMPTS) return 'retry';
  return 'failed';
}

function pushUpdate(result: DispatchResult, delivered: number, now: Date): Record<string, unknown> {
  switch (result) {
    case 'sent':
      return {
        'push.state': 'sent',
        'push.devices': delivered,
        'push.sentAt': Timestamp.fromDate(now),
      };
    case 'retry':
      return {
        'push.state': 'pending',
        'push.sendAfter': Timestamp.fromMillis(now.getTime() + RETRY_AFTER_MS),
      };
    default:
      return { 'push.state': 'failed' };
  }
}
