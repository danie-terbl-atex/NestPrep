import type { Firestore } from 'firebase-admin/firestore';

import { inboxDocument, type InboxDraft } from './inbox_item';
import { inboxRef, settingsRef } from './notification_refs';
import { readSettings, sendAfter, wantsCategory } from './notification_settings';
import { dispatchInboxItem, type DispatchResult } from './push_dispatch';
import type { PushSender } from './push_sender';

/**
 * The one way anything reaches a person (notifications ADR-0001): a producer
 * — the digest, an expiry reminder, a shift's handover, a chore to check —
 * hands over drafts, and this puts each into its person's inbox and sends the
 * push that can go now.
 *
 * Each person's own choices decide (ADR-0003): a category they switched off
 * writes nothing; inside their quiet hours the inbox has it at once and the
 * buzz waits for the morning, when the delivery job sends it.
 */
export interface DeliveryContext {
  readonly store: Firestore;
  readonly sender: PushSender;
  readonly householdId: string;
  readonly zone: string;
  readonly now: Date;
}

export interface DeliveryReport {
  readonly created: number;
  readonly declined: number;
  readonly dispatched: readonly DispatchResult[];
}

export async function deliverDrafts(
  context: DeliveryContext,
  drafts: readonly InboxDraft[],
): Promise<DeliveryReport> {
  const { store, householdId, zone, now } = context;
  if (drafts.length === 0) return { created: 0, declined: 0, dispatched: [] };

  const memberIds = [...new Set(drafts.map((draft) => draft.memberId))];
  const stored = await store.getAll(...memberIds.map((id) => settingsRef(store, householdId, id)));
  const settingsOf = Object.fromEntries(
    stored.map((snapshot) => [snapshot.id, readSettings(snapshot.data())]),
  );

  const wanted = drafts.flatMap((draft) => {
    const settings = settingsOf[draft.memberId] ?? readSettings(undefined);
    if (!wantsCategory(settings, draft.category)) return [];
    // A test is asked for, so it comes now; everything else keeps the
    // person's quiet hours.
    const after = draft.category === 'test' ? now : sendAfter(settings.quietHours, zone, now);
    return [{ draft, after }];
  });

  const created = await store.runTransaction(async (transaction) => {
    if (wanted.length === 0) return [];
    const refs = wanted.map(({ draft }) => inboxRef(store, householdId, draft.id));
    const existing = await transaction.getAll(...refs);
    return wanted.flatMap(({ draft, after }, index) => {
      const ref = refs[index];
      if (ref === undefined || existing[index]?.exists === true) return [];
      transaction.create(ref, inboxDocument(draft, after, now));
      return [{ id: draft.id, after }];
    });
  });

  const dispatched: DispatchResult[] = [];
  for (const item of created) {
    if (item.after.getTime() > now.getTime()) continue;
    dispatched.push(
      await dispatchInboxItem({
        store,
        sender: context.sender,
        householdId,
        itemId: item.id,
        now,
      }),
    );
  }
  return { created: created.length, declined: drafts.length - wanted.length, dispatched };
}
