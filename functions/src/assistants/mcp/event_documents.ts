import type { CollectionReference, DocumentData, Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { storedRecurrence, type StoredRecurrence } from '../../chore_points/occurrence_check';
import { HOUSEHOLDS } from '../../household/documents';
import { ASSISTANT_VIAS } from '../principal';
import { timeOf, type RecurrenceInput } from './validators';

/**
 * The calendar's documents as the app writes and reads them (calendar
 * ADR-0001, ADR-0002; assistants ADR-0005): `events/{id}` with every key the
 * Dart `HouseholdEvent.toJson` writes, plus `createdVia` on what an assistant
 * made, and `eventExceptions/{eventId}_{date}` for a skipped occurrence.
 */
export const EVENTS = 'events';
export const EVENT_EXCEPTIONS = 'eventExceptions';

/** As many events as the app's own calendar reads. */
export const EVENT_READ_LIMIT = 500;

/** The keys every event document carries, as the app writes them. */
export const EVENT_KEYS = [
  'title',
  'note',
  'date',
  'startMinute',
  'endMinute',
  'recurrence',
  'memberIds',
  'createdBy',
  'createdAt',
] as const;

/** The keys every skipped occurrence carries, as the app writes them. */
export const EXCEPTION_KEYS = ['eventId', 'occurrenceDate', 'skippedBy', 'skippedAt'] as const;

/** The fields the creator or an admin may change, the rules' `onlyChanged` list. */
export const EVENT_EDITABLE_KEYS = [
  'title',
  'note',
  'date',
  'startMinute',
  'endMinute',
  'recurrence',
  'memberIds',
] as const;

/**
 * A stored event, read the way the app reads one. A rule this build cannot
 * read is treated as happening once (`BE-10`), never as a broken calendar.
 */
export const storedHouseholdEvent = z.object({
  title: z.string(),
  note: z.string().nullable().optional(),
  date: z.string(),
  startMinute: z.number().int().nullable().optional(),
  endMinute: z.number().int().nullable().optional(),
  recurrence: storedRecurrence.nullable().optional().catch(null),
  memberIds: z.array(z.string()).catch([]).default([]),
  createdBy: z.string(),
  createdVia: z.enum(ASSISTANT_VIAS).optional().catch(undefined),
});
export type StoredHouseholdEvent = z.infer<typeof storedHouseholdEvent>;

/** What an event says, in the keys the rules let its creator change. */
export interface EventFields {
  readonly title: string;
  readonly note: string | null;
  readonly date: string;
  readonly startMinute: number | null;
  readonly endMinute: number | null;
  readonly recurrence: StoredRecurrence | null;
  readonly memberIds: readonly string[];
}

export function storedRuleOf(rule: RecurrenceInput | null): StoredRecurrence | null {
  return rule === null
    ? null
    : {
        frequency: rule.frequency,
        interval: rule.interval,
        weekdays: [...rule.weekdays].sort((a, b) => a - b),
        until: rule.until,
      };
}

export function fieldsOf(stored: StoredHouseholdEvent): EventFields {
  return {
    title: stored.title,
    note: stored.note ?? null,
    date: stored.date,
    startMinute: stored.startMinute ?? null,
    endMinute: stored.endMinute ?? null,
    recurrence: stored.recurrence ?? null,
    memberIds: stored.memberIds,
  };
}

/** The editable half of the document, every key present as the app writes it. */
export function eventData(fields: EventFields): DocumentData {
  return {
    title: fields.title,
    note: fields.note,
    date: fields.date,
    startMinute: fields.startMinute,
    endMinute: fields.endMinute,
    recurrence: fields.recurrence === null ? null : { ...fields.recurrence },
    memberIds: [...fields.memberIds],
  };
}

export function exceptionIdOf(eventId: string, occurrenceDate: string): string {
  return `${eventId}_${occurrenceDate}`;
}

export function eventsOf(store: Firestore, householdId: string): CollectionReference {
  return store.collection(HOUSEHOLDS).doc(householdId).collection(EVENTS);
}

export function exceptionsOf(store: Firestore, householdId: string): CollectionReference {
  return store.collection(HOUSEHOLDS).doc(householdId).collection(EVENT_EXCEPTIONS);
}

export const toolRecurrence = z.object({
  frequency: z.enum(['daily', 'weekly', 'monthly']),
  interval: z.number().int(),
  weekdays: z.array(z.number().int()),
  until: z.string().nullable(),
});

/** An event as a tool answers with it. */
export const toolEvent = z.object({
  id: z.string(),
  title: z.string(),
  note: z.string().nullable(),
  date: z.string().describe('The first (or only) day, YYYY-MM-DD.'),
  all_day: z.boolean(),
  start_time: z.string().nullable(),
  end_time: z.string().nullable(),
  recurrence: toolRecurrence.nullable(),
  member_ids: z.array(z.string()),
  created_by: z.string(),
  created_via: z.enum(ASSISTANT_VIAS).nullable(),
});
export type ToolEvent = z.infer<typeof toolEvent>;

export function toToolEvent(
  id: string,
  fields: EventFields,
  createdBy: string,
  createdVia: StoredHouseholdEvent['createdVia'] | null,
): ToolEvent {
  return {
    id,
    title: fields.title,
    note: fields.note,
    date: fields.date,
    all_day: fields.startMinute === null,
    start_time: fields.startMinute === null ? null : timeOf(fields.startMinute),
    end_time: fields.endMinute === null ? null : timeOf(fields.endMinute),
    recurrence: fields.recurrence === null ? null : { ...fields.recurrence },
    member_ids: [...fields.memberIds],
    created_by: createdBy,
    created_via: createdVia ?? null,
  };
}
