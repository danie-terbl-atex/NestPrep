import {
  FieldValue,
  type DocumentData,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import { z } from 'zod';

import { isOccurrence } from '../../../chore_points/occurrence_check';
import { requireAccess, type AssistantMember } from '../../assistant_access';
import { AssistantRefusal, type AssistantPrincipal } from '../../principal';
import { consumeWriteAllowance, recordActivity, type ActivityTarget } from '../activity_log';
import {
  readEvent,
  requireKnownMembers,
  requireMayChange,
  requireRuleFits,
} from '../calendar_checks';
import {
  EVENT_EDITABLE_KEYS,
  eventData,
  eventsOf,
  exceptionIdOf,
  exceptionsOf,
  fieldsOf,
  storedRuleOf,
  toToolEvent,
  toolEvent,
  type EventFields,
  type StoredHouseholdEvent,
} from '../event_documents';
import type { AssistantTool } from '../tool';
import {
  calendarDate,
  documentId,
  eventNote,
  eventTitle,
  memberIds,
  minuteOf,
  recurrenceInput,
  wallClockTime,
} from '../validators';

const MINUTES_IN_A_DAY = 24 * 60;

const scope = z
  .enum(['occurrence', 'series'])
  .optional()
  .describe(
    'For a repeating event: "occurrence" for just the one on occurrence_date, "series" for every one. Required when the event repeats.',
  );

const occurrenceDate = calendarDate
  .optional()
  .describe('With scope "occurrence": the day of the occurrence meant, YYYY-MM-DD.');

/** Where a recurring event's change lands, decided from the scope asked for. */
type Target = { kind: 'whole' } | { kind: 'occurrence'; date: string };

function targetOf(
  stored: StoredHouseholdEvent,
  eventId: string,
  asked: 'occurrence' | 'series' | undefined,
  date: string | undefined,
): Target {
  const recurrence = stored.recurrence ?? null;
  if (recurrence === null) return { kind: 'whole' };
  if (asked === undefined) {
    throw new AssistantRefusal(
      'badRequest',
      'scopeNeeded',
      'This event repeats. Say scope "occurrence" (with occurrence_date) for one day, or "series" for all of them.',
    );
  }
  if (asked === 'series') return { kind: 'whole' };
  if (date === undefined || !isOccurrence(stored.date, recurrence, date)) {
    throw new AssistantRefusal(
      'badRequest',
      'notAnOccurrence',
      `Event ${eventId} does not happen on that day. Give an occurrence_date it happens on (list_events shows them).`,
    );
  }
  return { kind: 'occurrence', date };
}

async function requireNotSkipped(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  eventId: string,
  date: string,
): Promise<void> {
  const skipped = await transaction.get(
    exceptionsOf(store, householdId).doc(exceptionIdOf(eventId, date)),
  );
  if (!skipped.exists) return;
  throw new AssistantRefusal(
    'notFound',
    'alreadySkipped',
    'That occurrence has already been removed from the calendar.',
  );
}

function stageSkip(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  eventId: string,
  date: string,
  memberId: string,
): void {
  transaction.set(exceptionsOf(store, householdId).doc(exceptionIdOf(eventId, date)), {
    eventId,
    occurrenceDate: date,
    skippedBy: memberId,
    skippedAt: FieldValue.serverTimestamp(),
  });
}

const updateInput = z.strictObject({
  event_id: documentId.describe('The event to change, from list_events or create_event.'),
  scope,
  occurrence_date: occurrenceDate,
  title: eventTitle.optional(),
  date: calendarDate.optional().describe('Move it to this day, YYYY-MM-DD.'),
  start_time: wallClockTime
    .nullable()
    .optional()
    .describe(
      'New start, HH:MM 24-hour; null makes it all day. Moving the start alone keeps how long it lasts.',
    ),
  end_time: wallClockTime.nullable().optional().describe('New end, HH:MM 24-hour.'),
  note: eventNote.nullable().optional().describe('New note; null or "" removes it.'),
  member_ids: memberIds.optional(),
  recurrence: recurrenceInput
    .nullable()
    .optional()
    .describe('Series only: the new repeat rule, or null to make it a one-off.'),
});

type UpdateArgs = z.output<typeof updateInput>;

function refuseEndWithoutStart(): never {
  throw new AssistantRefusal(
    'badRequest',
    'endWithoutStart',
    'An all-day event has no end time. Give a start time too, or leave the end out.',
  );
}

/** The times once a change is applied; a start moved alone keeps the length. */
function timesAfter(
  current: EventFields,
  startTime: string | null | undefined,
  endTime: string | null | undefined,
): { startMinute: number | null; endMinute: number | null } {
  if (startTime === null) {
    if (endTime !== undefined && endTime !== null) refuseEndWithoutStart();
    return { startMinute: null, endMinute: null };
  }
  if (startTime === undefined && endTime === undefined) {
    return { startMinute: current.startMinute, endMinute: current.endMinute };
  }
  const startMinute = startTime === undefined ? current.startMinute : minuteOf(startTime);
  if (startMinute === null) refuseEndWithoutStart();
  if (endTime !== undefined) {
    return { startMinute, endMinute: endTime === null ? null : minuteOf(endTime) };
  }
  if (current.startMinute === null || current.endMinute === null) {
    return { startMinute, endMinute: current.endMinute };
  }
  const length = (current.endMinute - current.startMinute + MINUTES_IN_A_DAY) % MINUTES_IN_A_DAY;
  return { startMinute, endMinute: (startMinute + length) % MINUTES_IN_A_DAY };
}

function noteAfter(current: string | null, asked: string | null | undefined): string | null {
  if (asked === undefined) return current;
  return asked === null || asked === '' ? null : asked;
}

/** The event as it reads once the asked changes are applied to [current]. */
function changedFields(current: EventFields, args: UpdateArgs): EventFields {
  return {
    title: args.title ?? current.title,
    note: noteAfter(current.note, args.note),
    date: args.date ?? current.date,
    ...timesAfter(current, args.start_time, args.end_time),
    recurrence: args.recurrence === undefined ? current.recurrence : storedRuleOf(args.recurrence),
    memberIds: args.member_ids === undefined ? current.memberIds : [...new Set(args.member_ids)],
  };
}

function asksForAChange(args: UpdateArgs): boolean {
  return [
    args.title,
    args.date,
    args.start_time,
    args.end_time,
    args.note,
    args.member_ids,
    args.recurrence,
  ].some((value) => value !== undefined);
}

/** Only the keys whose stored value moves, so the write is the rules' `onlyChanged`. */
function changesBetween(before: EventFields, after: EventFields): DocumentData {
  const was = eventData(before);
  const now = eventData(after);
  return Object.fromEntries(
    EVENT_EDITABLE_KEYS.filter((key) => JSON.stringify(was[key]) !== JSON.stringify(now[key])).map(
      (key) => [key, now[key]],
    ),
  );
}

const updateOutput = z.object({
  changed: z.enum(['event', 'series', 'occurrence']),
  event: toolEvent.describe(
    'The event as it now reads. For an occurrence this is the new one-off event that replaces it.',
  ),
  skipped_occurrence: z.string().nullable(),
});

interface ChangeContext {
  readonly store: Firestore;
  readonly principal: AssistantPrincipal;
  readonly access: AssistantMember;
  readonly now: Date;
}

function logChange(
  transaction: Transaction,
  context: ChangeContext,
  tool: string,
  targets: readonly ActivityTarget[],
): void {
  recordActivity(
    transaction,
    context.store,
    { principal: context.principal, memberId: context.access.memberId },
    tool,
    targets,
    context.now,
  );
}

/**
 * `update_event` (assistants ADR-0001, ADR-0005): the creator or an admin
 * changes an event, as the rules allow. A whole event or series is updated
 * in the keys that moved; one occurrence of a repeat is skipped the way the
 * app skips it and replaced by a one-off carrying the change, because an
 * occurrence can be skipped but not moved (calendar ADR-0001).
 */
export const updateEvent: AssistantTool<typeof updateInput, typeof updateOutput> = {
  name: 'update_event',
  title: 'Change a calendar event',
  description:
    'Changes an event on the NestPrep calendar: its title, day, times, note, who it is for, or how it repeats. Only send the fields that change. Dates are YYYY-MM-DD and times the household\'s 24-hour wall clock (HH:MM); moving only the start keeps the length. For a repeating event say scope "series" for every occurrence, or "occurrence" with occurrence_date for just that day (e.g. "move Saturday\'s swimming to 10:00"). Only the member who added the event, or a household admin, can change it.',
  scope: 'calendar:write',
  annotations: {
    readOnlyHint: false,
    destructiveHint: true,
    idempotentHint: true,
    openWorldHint: false,
  },
  input: updateInput,
  output: updateOutput,
  run: async (store, principal, args, now) => {
    const access = await requireAccess(store, principal, 'calendar:write', now);
    if (!asksForAChange(args)) {
      throw new AssistantRefusal('badRequest', 'nothingToChange', 'Say what to change.');
    }
    await consumeWriteAllowance(store, principal, now);
    const context: ChangeContext = { store, principal, access, now };
    const events = eventsOf(store, principal.householdId);

    return store.runTransaction(async (transaction) => {
      const stored = await readEvent(transaction, store, principal.householdId, args.event_id);
      requireMayChange(access, stored);
      const target = targetOf(stored, args.event_id, args.scope, args.occurrence_date);
      const current = fieldsOf(stored);

      if (target.kind === 'whole') {
        const after = changedFields(current, args);
        requireRuleFits(after);
        if (args.member_ids !== undefined) {
          await requireKnownMembers(transaction, store, principal.householdId, after.memberIds);
        }
        const changes = changesBetween(current, after);
        if (Object.keys(changes).length > 0) {
          transaction.update(events.doc(args.event_id), changes);
          logChange(transaction, context, 'update_event', [{ kind: 'event', id: args.event_id }]);
        }
        return {
          changed: current.recurrence === null ? ('event' as const) : ('series' as const),
          event: toToolEvent(args.event_id, after, stored.createdBy, stored.createdVia ?? null),
          skipped_occurrence: null,
        };
      }

      if (args.recurrence !== undefined) {
        throw new AssistantRefusal(
          'badRequest',
          'recurrenceOnOccurrence',
          'One occurrence cannot repeat. Change the series to change how it repeats.',
        );
      }
      await requireNotSkipped(
        transaction,
        store,
        principal.householdId,
        args.event_id,
        target.date,
      );
      const after = changedFields({ ...current, date: target.date, recurrence: null }, args);
      if (args.member_ids !== undefined) {
        await requireKnownMembers(transaction, store, principal.householdId, after.memberIds);
      }
      const replacement = events.doc();
      stageSkip(
        transaction,
        store,
        principal.householdId,
        args.event_id,
        target.date,
        access.memberId,
      );
      transaction.set(replacement, {
        ...eventData(after),
        createdBy: access.memberId,
        createdAt: FieldValue.serverTimestamp(),
        createdVia: principal.via,
      });
      logChange(transaction, context, 'update_event', [
        { kind: 'event', id: args.event_id },
        { kind: 'event', id: replacement.id },
      ]);
      return {
        changed: 'occurrence' as const,
        event: toToolEvent(replacement.id, after, access.memberId, principal.via),
        skipped_occurrence: target.date,
      };
    });
  },
};

const deleteInput = z.strictObject({
  event_id: documentId.describe('The event to delete, from list_events or create_event.'),
  scope,
  occurrence_date: occurrenceDate,
});

const deleteOutput = z.object({
  deleted: z.enum(['event', 'series', 'occurrence']),
  event_id: z.string(),
  occurrence_date: z.string().nullable(),
});

/**
 * `delete_event` (assistants ADR-0001, ADR-0005): the creator or an admin
 * deletes an event or a whole series, or skips one occurrence of a repeat
 * with the app's own `eventExceptions` document.
 */
export const deleteEvent: AssistantTool<typeof deleteInput, typeof deleteOutput> = {
  name: 'delete_event',
  title: 'Delete a calendar event',
  description:
    'Deletes an event from the NestPrep calendar. For a repeating event say scope "occurrence" with occurrence_date (YYYY-MM-DD) to remove just that day, or "series" to delete every occurrence. Only the member who added the event, or a household admin, can delete it. Confirm with the member before deleting a series.',
  scope: 'calendar:write',
  annotations: {
    readOnlyHint: false,
    destructiveHint: true,
    idempotentHint: false,
    openWorldHint: false,
  },
  input: deleteInput,
  output: deleteOutput,
  run: async (store, principal, args, now) => {
    const access = await requireAccess(store, principal, 'calendar:write', now);
    await consumeWriteAllowance(store, principal, now);
    const context: ChangeContext = { store, principal, access, now };

    return store.runTransaction(async (transaction) => {
      const stored = await readEvent(transaction, store, principal.householdId, args.event_id);
      requireMayChange(access, stored);
      const target = targetOf(stored, args.event_id, args.scope, args.occurrence_date);
      const logged: ActivityTarget[] = [{ kind: 'event', id: args.event_id }];
      if (target.kind === 'occurrence') {
        await requireNotSkipped(
          transaction,
          store,
          principal.householdId,
          args.event_id,
          target.date,
        );
        stageSkip(
          transaction,
          store,
          principal.householdId,
          args.event_id,
          target.date,
          access.memberId,
        );
        logChange(transaction, context, 'delete_event', logged);
        return {
          deleted: 'occurrence' as const,
          event_id: args.event_id,
          occurrence_date: target.date,
        };
      }
      transaction.delete(eventsOf(store, principal.householdId).doc(args.event_id));
      logChange(transaction, context, 'delete_event', logged);
      return {
        deleted: (stored.recurrence ?? null) === null ? ('event' as const) : ('series' as const),
        event_id: args.event_id,
        occurrence_date: null,
      };
    });
  },
};
