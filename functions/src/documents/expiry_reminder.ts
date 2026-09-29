import type { FieldValue } from 'firebase-admin/firestore';

import type { ReminderScope } from './expiry_schedule';

/**
 * `households/{h}/expiryReminders/{id}` — **the contract the notifications
 * feature delivers** (documents ADR-0005). Only the Admin SDK writes it; the
 * catch-all in `firestore.rules` refuses every client read and write.
 *
 * Notifications decides who receives one and **re-reads the document before
 * sending**: if it has gone, or its `expiresOn` no longer equals this one, the
 * reminder is stale and is marked `skipped`. Fields are only ever added
 * (BE-17).
 */
export const EXPIRY_REMINDERS = 'expiryReminders';

export type ReminderStatus = 'pending' | 'sent' | 'skipped';

export interface ExpiryReminderDocument {
  /** `vault` for a personal vault, `household` for the shared folders. */
  readonly scope: ReminderScope;
  /** The vault's member, or null for a household document. */
  readonly ownerMemberId: string | null;
  readonly documentId: string;
  /** The name when the reminder was made; the document may be renamed later. */
  readonly documentName: string;
  /** `YYYY-MM-DD` in the household's zone — the date this was computed for. */
  readonly expiresOn: string;
  /** 90, 30, 7, or 0 for "today, or already expired". */
  readonly daysBefore: number;
  /** The household-local day it became due. */
  readonly dueOn: string;
  /** Written `pending`; notifications moves it to `sent` or `skipped`. */
  readonly status: ReminderStatus;
  readonly createdAt: FieldValue;
}
