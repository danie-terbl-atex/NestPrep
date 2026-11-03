import type { Firestore, Transaction } from 'firebase-admin/firestore';

import { isOccurrence } from '../../chore_points/occurrence_check';
import { normalisedName } from '../../home_care/restock_decision';
import { memberRef } from '../../household/documents';
import type { AssistantMember } from '../assistant_access';
import { AssistantRefusal } from '../principal';
import {
  EVENT_READ_LIMIT,
  eventsOf,
  exceptionIdOf,
  exceptionsOf,
  storedHouseholdEvent,
  type EventFields,
  type StoredHouseholdEvent,
} from './event_documents';
import { minuteOf } from './validators';

/**
 * The checks an assistant's calendar write makes that the rules make, or
 * that only a server can (assistants ADR-0001): every member named is one of
 * this household's, only the creator or an admin changes an event, and the
 * same title on the same day is a duplicate until the member says otherwise.
 */

/** Refuses unless every id is a member profile of this household. */
export async function requireKnownMembers(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  memberIds: readonly string[],
): Promise<void> {
  if (memberIds.length === 0) return;
  const profiles = await transaction.getAll(
    ...memberIds.map((id) => memberRef(store, householdId, id)),
  );
  if (profiles.every((profile) => profile.exists)) return;
  throw new AssistantRefusal(
    'badRequest',
    'unknownMember',
    'One of those member ids is not in this household. Use the ids get_household returns.',
  );
}

/** The rules' edit and delete test: the event's creator, or an admin. */
export function requireMayChange(access: AssistantMember, stored: StoredHouseholdEvent): void {
  if (access.role === 'admin' || stored.createdBy === access.memberId) return;
  throw new AssistantRefusal(
    'forbidden',
    'notTheCreator',
    'Only the person who added this event, or a household admin, can change or delete it.',
  );
}

/** Reads one event in the transaction, or refuses `notFound`. */
export async function readEvent(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  eventId: string,
): Promise<StoredHouseholdEvent> {
  const snapshot = await transaction.get(eventsOf(store, householdId).doc(eventId));
  const parsed = storedHouseholdEvent.safeParse(snapshot.data());
  if (!snapshot.exists || !parsed.success) {
    throw new AssistantRefusal('notFound', 'eventNotFound', 'There is no event with that id.');
  }
  return parsed.data;
}

/**
 * Events already on [date] under the same normalised title — a one-off on
 * that day, or a repeat that lands on it and was not skipped.
 */
export async function sameEventsOn(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  title: string,
  date: string,
): Promise<string[]> {
  const key = normalisedName(title);
  const [events, skipped] = await Promise.all([
    transaction.get(eventsOf(store, householdId).limit(EVENT_READ_LIMIT)),
    transaction.get(exceptionsOf(store, householdId).where('occurrenceDate', '==', date)),
  ]);
  const skippedIds = new Set(skipped.docs.map((doc) => doc.id));
  return events.docs.flatMap((doc) => {
    const event = storedHouseholdEvent.safeParse(doc.data());
    if (!event.success || normalisedName(event.data.title) !== key) return [];
    if (skippedIds.has(exceptionIdOf(doc.id, date))) return [];
    return isOccurrence(event.data.date, event.data.recurrence ?? null, date) ? [doc.id] : [];
  });
}

/** Refuses `possible_duplicate` when [sameEventsOn] found any. */
export function refuseDuplicate(title: string, date: string, existing: readonly string[]): never {
  throw new AssistantRefusal(
    'conflict',
    'possible_duplicate',
    `possible_duplicate: "${title}" is already on the calendar on ${date} (event ${existing.join(', ')}). ` +
      'If the member really wants a second one, call create_event again with confirm_duplicate: true; otherwise use that event.',
  );
}

/** Times as the rules store them; an end with no start is not a time. */
export function minutesOf(
  start: string | null | undefined,
  end: string | null | undefined,
): { startMinute: number | null; endMinute: number | null } {
  const startMinute = start === null || start === undefined ? null : minuteOf(start);
  const endMinute = end === null || end === undefined ? null : minuteOf(end);
  if (startMinute === null && endMinute !== null) {
    throw new AssistantRefusal(
      'badRequest',
      'endWithoutStart',
      'An event with an end time needs a start time. Leave both out for an all-day event.',
    );
  }
  return { startMinute, endMinute };
}

/** Refuses a repeat that ends before it starts. */
export function requireRuleFits(fields: EventFields): void {
  const until = fields.recurrence?.until ?? null;
  if (until === null || until >= fields.date) return;
  throw new AssistantRefusal(
    'badRequest',
    'untilBeforeDate',
    'A repeat cannot end before its first day.',
  );
}
