import { FieldValue, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { z } from 'zod';

import {
  INBOX_RETENTION_DAYS,
  NOTIFICATION_CATEGORIES,
  NOTIFICATION_TARGETS,
  PUSH_STATES,
  type NotificationCategory,
  type NotificationTarget,
} from './notification_contract';
import type { DigestSection } from './digest_sections';
import type { PushText } from './push_text';

/**
 * `households/{h}/notificationInbox/{id}` — one notification for one person,
 * and the unit everything in this feature delivers (notifications ADR-0001).
 * The app's inbox reads it; the push is sent from it. Only Functions create
 * one; its reader may mark it read or delete it, and nothing else.
 *
 * Its id is derived from what it is about and who it is for, so a producer
 * delivered twice — a retried trigger, a sweep that overlaps a trigger —
 * creates it once (BE-06, BE-15).
 */

export interface InboxTarget {
  readonly kind: NotificationTarget;
  readonly id: string | null;
}

export interface InboxDraft {
  readonly id: string;
  readonly memberId: string;
  readonly category: NotificationCategory;
  /** What the lock screen shows — counts and kinds only (`push_text.ts`). */
  readonly text: PushText;
  /** One more line, shown only in the app, behind the rules. */
  readonly detail: string | null;
  readonly sections: readonly DigestSection[];
  readonly target: InboxTarget;
  readonly source: { readonly kind: string; readonly id: string };
  /** `YYYY-MM-DD` on the household's clock — the day it is about. */
  readonly localDate: string;
}

const DAY_MS = 24 * 60 * 60 * 1000;

/** How many times a push is tried before the inbox is all it gets. */
export const MAX_PUSH_ATTEMPTS = 3;

export function inboxDocument(draft: InboxDraft, sendAfter: Date, now: Date): DocumentData {
  return {
    memberId: draft.memberId,
    category: draft.category,
    title: draft.text.title,
    body: draft.text.body,
    detail: draft.detail,
    sections: draft.sections.map((section) => ({
      kind: section.kind,
      total: section.total,
      items: section.items.map((item) => ({ text: item.text, detail: item.detail })),
    })),
    target: { kind: draft.target.kind, id: draft.target.id },
    source: { kind: draft.source.kind, id: draft.source.id },
    localDate: draft.localDate,
    createdAt: FieldValue.serverTimestamp(),
    readAt: null,
    // Firestore's TTL policy on `expireAt` removes it; nothing has to remember.
    expireAt: Timestamp.fromMillis(now.getTime() + INBOX_RETENTION_DAYS * DAY_MS),
    push: { state: 'pending', sendAfter: Timestamp.fromDate(sendAfter), attempts: 0 },
  };
}

/** What a dispatch needs back off a stored item, parsed and never cast (ENG-09). */
export const storedInboxItem = z.object({
  memberId: z.string(),
  category: z.enum(NOTIFICATION_CATEGORIES),
  title: z.string(),
  body: z.string(),
  target: z.object({ kind: z.enum(NOTIFICATION_TARGETS), id: z.string().nullable() }),
  push: z.object({
    state: z.enum(PUSH_STATES),
    sendAfter: z.instanceof(Timestamp),
    attempts: z.number().int().min(0).default(0),
  }),
});
export type StoredInboxItem = z.infer<typeof storedInboxItem>;
