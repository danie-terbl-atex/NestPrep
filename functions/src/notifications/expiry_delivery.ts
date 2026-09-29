import { FieldValue, type Firestore, type QueryDocumentSnapshot } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { DOCUMENTS } from '../documents/document_refs';
import { EXPIRY_REMINDERS } from '../documents/expiry_reminder';
import { VAULTS, VAULT_DOCUMENTS } from '../documents/vault_refs';
import { householdRef } from '../household/documents';
import { expiryText } from './digest_sections';
import { loadRoster, type HouseholdRoster } from './household_roster';
import { deliverDrafts } from './inbox_delivery';
import type { InboxDraft } from './inbox_item';
import type { PushSender } from './push_sender';
import { expiryPushText } from './push_text';
import { canSee, type Recipient } from './recipients';

/**
 * Delivers the expiry reminders documents writes (documents ADR-0005 — this is
 * its consumer). For each `pending` reminder it re-reads the document: gone,
 * or its date changed since, and the reminder is stale and marked `skipped`.
 * Otherwise it goes to whoever may see it — a household document to everyone
 * with the documents grant; a vault document to its owner and the household's
 * admins, as ADR-0005 asks — and is marked `sent`.
 *
 * Idempotent: every inbox item's id is the reminder and the person, so a run
 * that dies between delivering and marking delivers nothing twice the next time.
 */
export const REMINDER_PAGE = 100;
export const REMINDER_PAGES = 5;

export const pendingReminder = z.object({
  scope: z.enum(['vault', 'household']),
  ownerMemberId: z.string().nullable(),
  documentId: z.string(),
  documentName: z.string().default(''),
  expiresOn: z.string(),
  daysBefore: z.number().int(),
  dueOn: z.string(),
  status: z.literal('pending'),
});
export type PendingReminder = z.infer<typeof pendingReminder>;

/** Who hears about one reminder. Pure, and tested (ADR-0005, household ADR-0003). */
export function reminderRecipients(
  roster: HouseholdRoster,
  reminder: PendingReminder,
): Recipient[] {
  if (reminder.scope === 'household') {
    return roster.recipients.filter((recipient) => canSee(recipient, 'documents'));
  }
  return roster.recipients.filter(
    (recipient) =>
      (recipient.memberId === reminder.ownerMemberId && recipient.hasAccount) ||
      recipient.role === 'admin',
  );
}

export function reminderDrafts(
  reminderId: string,
  reminder: PendingReminder,
  recipients: readonly Recipient[],
): InboxDraft[] {
  const inVault = reminder.scope === 'vault';
  const when = expiryText(reminder.dueOn, reminder.expiresOn);
  return recipients.map((recipient) => ({
    id: `expiry_${reminderId}_${recipient.memberId}`,
    memberId: recipient.memberId,
    category: 'documents',
    text: expiryPushText(reminder.daysBefore, inVault),
    // Named in the app for a household document; a vault one is named only
    // inside its vault (documents ADR-0003).
    detail: inVault ? `A document in a vault · ${when}` : `${reminder.documentName} · ${when}`,
    sections: [],
    target: inVault
      ? { kind: 'vault', id: reminder.ownerMemberId }
      : { kind: 'documents', id: reminder.documentId },
    source: { kind: 'expiryReminder', id: reminderId },
    localDate: reminder.dueOn,
  }));
}

async function isStillDue(
  store: Firestore,
  householdId: string,
  reminder: PendingReminder,
): Promise<boolean> {
  const home = householdRef(store, householdId);
  const ref =
    reminder.scope === 'vault'
      ? home
          .collection(VAULTS)
          .doc(reminder.ownerMemberId ?? '')
          .collection(VAULT_DOCUMENTS)
          .doc(reminder.documentId)
      : home.collection(DOCUMENTS).doc(reminder.documentId);
  const snapshot = await ref.get();
  return snapshot.exists && snapshot.get('expiresOn') === reminder.expiresOn;
}

export interface ReminderReport {
  examined: number;
  sent: number;
  skipped: number;
}

async function deliverOne(
  store: Firestore,
  sender: PushSender,
  document: QueryDocumentSnapshot,
  now: Date,
): Promise<'sent' | 'skipped'> {
  const householdId = document.ref.path.split('/')[1] ?? '';
  const reminder = pendingReminder.safeParse(document.data());
  const why = reminder.success
    ? await whyNot(store, householdId, reminder.data)
    : { reason: 'unreadable' as const, roster: null };
  if (reminder.success && why.reason === null && why.roster !== null) {
    await deliverDrafts(
      { store, sender, householdId, zone: why.roster.zone, now },
      reminderDrafts(document.id, reminder.data, reminderRecipients(why.roster, reminder.data)),
    );
  }
  // Marked after delivering, so a run that dies in between delivers again —
  // and creates nothing, because every item's id is already there.
  const batch = store.batch();
  batch.update(
    document.ref,
    why.reason === null
      ? { status: 'sent', sentAt: FieldValue.serverTimestamp() }
      : { status: 'skipped', skippedBecause: why.reason },
  );
  await batch.commit();
  return why.reason === null ? 'sent' : 'skipped';
}

type SkipReason = 'unreadable' | 'stale' | 'nobody' | null;

/** Why a reminder will not be delivered, or null when it will. */
async function whyNot(
  store: Firestore,
  householdId: string,
  reminder: PendingReminder,
): Promise<{ reason: SkipReason; roster: HouseholdRoster | null }> {
  const roster = await loadRoster(store, householdId);
  if (roster === null) return { reason: 'nobody', roster };
  if (!(await isStillDue(store, householdId, reminder))) return { reason: 'stale', roster };
  if (reminderRecipients(roster, reminder).length === 0) return { reason: 'nobody', roster };
  return { reason: null, roster };
}

export async function deliverExpiryReminders(
  store: Firestore,
  sender: PushSender,
  now: Date,
): Promise<ReminderReport> {
  const report: ReminderReport = { examined: 0, sent: 0, skipped: 0 };
  for (let page = 0; page < REMINDER_PAGES; page += 1) {
    // Each pass marks what it read, so the next page is the next query.
    const snapshot = await store
      .collectionGroup(EXPIRY_REMINDERS)
      .where('status', '==', 'pending')
      .limit(REMINDER_PAGE)
      .get();
    if (snapshot.empty) break;
    for (const document of snapshot.docs) {
      report.examined += 1;
      const outcome = await deliverOne(store, sender, document, now);
      if (outcome === 'sent') report.sent += 1;
      if (outcome === 'skipped') report.skipped += 1;
    }
    if (snapshot.size < REMINDER_PAGE) break;
  }
  logger.info('expiry reminders delivered', { ...report });
  return report;
}
