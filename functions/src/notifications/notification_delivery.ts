import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { deliverExpiryReminders, type ReminderReport } from './expiry_delivery';
import { NOTIFICATION_INBOX } from './notification_refs';
import { dispatchInboxItem, type DispatchResult } from './push_dispatch';
import type { PushSender } from './push_sender';
import { deliverPendingSummaries } from './shift_delivery';

/**
 * The delivery job's run, apart from its schedule so the emulator suite can
 * drive it with a fixed clock (notifications ADR-0001, BE-15). Three passes,
 * each bounded and each safe to run twice:
 *
 * 1. the pending expiry reminders documents wrote (documents ADR-0005);
 * 2. any shift handover the trigger never reached (nanny-hub ADR-0002);
 * 3. every push that is due now and not yet sent — held by somebody's quiet
 *    hours, or put back after an outage.
 */
export const DUE_PAGE = 100;
export const DUE_PAGES = 5;

export interface DeliveryRunReport {
  readonly reminders: ReminderReport;
  readonly handovers: number;
  readonly pushes: Readonly<Partial<Record<DispatchResult, number>>>;
}

async function sendDuePushes(
  store: Firestore,
  sender: PushSender,
  now: Date,
): Promise<Partial<Record<DispatchResult, number>>> {
  const tally: Partial<Record<DispatchResult, number>> = {};
  for (let page = 0; page < DUE_PAGES; page += 1) {
    // Each item leaves the query as it is claimed, so the next page is the
    // next query from the top.
    const due = await store
      .collectionGroup(NOTIFICATION_INBOX)
      .where('push.state', '==', 'pending')
      .where('push.sendAfter', '<=', Timestamp.fromDate(now))
      .orderBy('push.sendAfter')
      .limit(DUE_PAGE)
      .get();
    for (const item of due.docs) {
      const householdId = item.ref.path.split('/')[1];
      if (householdId === undefined) continue;
      const result = await dispatchInboxItem({ store, sender, householdId, itemId: item.id, now });
      tally[result] = (tally[result] ?? 0) + 1;
    }
    if (due.size < DUE_PAGE) break;
  }
  return tally;
}

export async function runNotificationDelivery(
  store: Firestore,
  sender: PushSender,
  now: Date,
): Promise<DeliveryRunReport> {
  const reminders = await deliverExpiryReminders(store, sender, now);
  const handovers = await deliverPendingSummaries(store, sender, now);
  const pushes = await sendDuePushes(store, sender, now);
  const report = { reminders, handovers, pushes };
  logger.info('notifications delivered', { ...reminders, handovers, ...pushes });
  return report;
}
