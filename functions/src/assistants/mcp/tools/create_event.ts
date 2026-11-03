import { FieldValue } from 'firebase-admin/firestore';
import { z } from 'zod';

import { requireAccess } from '../../assistant_access';
import { recordActivity, consumeWriteAllowance } from '../activity_log';
import {
  minutesOf,
  refuseDuplicate,
  requireKnownMembers,
  requireRuleFits,
  sameEventsOn,
} from '../calendar_checks';
import {
  eventData,
  eventsOf,
  storedRuleOf,
  toToolEvent,
  toolEvent,
  type EventFields,
} from '../event_documents';
import type { AssistantTool } from '../tool';
import {
  calendarDate,
  eventNote,
  eventTitle,
  memberIds,
  recurrenceInput,
  wallClockTime,
} from '../validators';

const input = z.strictObject({
  title: eventTitle.describe('What it is, as the family would write it: "Emma\'s swimming".'),
  date: calendarDate.describe(
    'The day, YYYY-MM-DD, in the household time zone. For a repeating event, the first day.',
  ),
  start_time: wallClockTime.optional().describe('Start, HH:MM 24-hour. Leave out for all day.'),
  end_time: wallClockTime
    .optional()
    .describe('End, HH:MM 24-hour. Earlier than the start means it runs past midnight.'),
  note: eventNote.optional().describe('Anything else worth knowing: the address, what to bring.'),
  member_ids: memberIds.default([]),
  recurrence: recurrenceInput.optional().describe('How it repeats. Leave out for a one-off.'),
  confirm_duplicate: z
    .boolean()
    .default(false)
    .describe(
      'Set true only after a possible_duplicate refusal, when the member confirms it is a second event.',
    ),
});

const output = z.object({
  event: toolEvent,
});

/**
 * `create_event` (assistants ADR-0001, ADR-0005): writes exactly the document
 * the app writes — the household's wall clock, never an instant (calendar
 * ADR-0002) — in the caller's member's name, with the server's time and the
 * assistant it came through. The members named must be this household's, and
 * the same title on the same day is refused as `possible_duplicate` unless
 * the member confirmed it. One activity line in the same transaction.
 */
export const createEvent: AssistantTool<typeof input, typeof output> = {
  name: 'create_event',
  title: 'Add a calendar event',
  description:
    'Adds an event to the NestPrep household calendar, as the member this connection belongs to. Call get_household first for member ids and today\'s date. Dates are YYYY-MM-DD and times are the household\'s wall clock in 24-hour HH:MM (e.g. a 3 pm party is "15:00"); leave both times out for an all-day event. Read what you need from a photo or message yourself and pass the details here. If something with the same title is already on that day the call is refused with possible_duplicate: ask the member, then call again with confirm_duplicate: true only if they want a second one. Returns the saved event.',
  scope: 'calendar:write',
  annotations: {
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: false,
    openWorldHint: false,
  },
  input,
  output,
  run: async (store, principal, args, now) => {
    const access = await requireAccess(store, principal, 'calendar:write', now);
    const fields: EventFields = {
      title: args.title,
      note: args.note === undefined || args.note === '' ? null : args.note,
      date: args.date,
      ...minutesOf(args.start_time, args.end_time),
      recurrence: storedRuleOf(args.recurrence ?? null),
      memberIds: [...new Set(args.member_ids)],
    };
    requireRuleFits(fields);
    await consumeWriteAllowance(store, principal, now);

    const ref = eventsOf(store, principal.householdId).doc();
    await store.runTransaction(async (transaction) => {
      await requireKnownMembers(transaction, store, principal.householdId, fields.memberIds);
      if (!args.confirm_duplicate) {
        const existing = await sameEventsOn(
          transaction,
          store,
          principal.householdId,
          fields.title,
          fields.date,
        );
        if (existing.length > 0) refuseDuplicate(fields.title, fields.date, existing);
      }
      transaction.set(ref, {
        ...eventData(fields),
        createdBy: access.memberId,
        createdAt: FieldValue.serverTimestamp(),
        createdVia: principal.via,
      });
      recordActivity(
        transaction,
        store,
        { principal, memberId: access.memberId },
        'create_event',
        [{ kind: 'event', id: ref.id }],
        now,
      );
    });
    return {
      event: toToolEvent(ref.id, fields, access.memberId, principal.via),
    };
  },
};
