import { daysInMonth, isoDate, weekdayOf } from '../calendar_sync/zoned_time';
import { badRequest } from '../household/parse_input';
import { type MemberRecord, type StoredHousehold, recipientsOf } from '../notifications/recipients';
import { refuseFrame } from './frame_errors';
import { FRAME_EVENT_REACH_MONTHS } from './frame_policy';
import type { AddFrameEventInput } from './frame_schemas';
import { membersNamed } from './frame_ticks';

/**
 * The rules of an event added at the wall (photo-frames ADR-0008), pure so
 * they are tested where they live (`BE-14`).
 */

/** Today to [FRAME_EVENT_REACH_MONTHS] ahead, in the household's zone. */
export function inEventReach(date: string, today: string): boolean {
  const [year, month, day] = today.split('-').map(Number) as [number, number, number];
  const index = year * 12 + month - 1 + FRAME_EVENT_REACH_MONTHS;
  const lastYear = Math.floor(index / 12);
  const lastMonth = (index % 12) + 1;
  const last = isoDate(lastYear, lastMonth, Math.min(day, daysInMonth(lastYear, lastMonth)));
  return date >= today && date <= last;
}

/**
 * The members who may add to the calendar, as the rules decide it: an
 * account or a kid device signed in as the profile, holding `calendar` at
 * `edit`. A profile nobody signs in as could not have added it in the app.
 */
export function calendarEditors(
  household: StoredHousehold,
  members: readonly MemberRecord[],
): string[] {
  return recipientsOf(household, members)
    .filter((recipient) => recipient.levels.calendar === 'edit')
    .map((recipient) => recipient.memberId);
}

/** The one calendar editor whose first name is [by]. */
export function adderNamed(
  editors: readonly string[],
  names: Readonly<Record<string, string>>,
  by: string,
): string {
  const [adder, ...others] = membersNamed(editors, names, by);
  if (adder === undefined) throw refuseFrame('notAllowedToAdd');
  if (others.length > 0) throw refuseFrame('whoNeeded');
  return adder;
}

/** The member ids [who] names, in order, each once; nobody named is everyone. */
export function peopleNamed(
  who: readonly string[],
  names: Readonly<Record<string, string>>,
): string[] {
  const everyone = Object.keys(names);
  const ids = who.map((name) => {
    const [id, ...others] = membersNamed(everyone, names, name);
    if (id === undefined) throw badRequest();
    if (others.length > 0) throw refuseFrame('whoNeeded');
    return id;
  });
  return [...new Set(ids)];
}

/** One id per frame and request, so a retry finds the event its first try wrote. */
export function frameEventId(frameId: string, requestId: string): string {
  return `frame-${frameId}-${requestId}`;
}

/**
 * Exactly what the app writes for this event, every key present as the rules
 * read them, less `createdAt`, which is the server's clock.
 */
export function frameEventDocument(
  input: AddFrameEventInput,
  createdBy: string,
  memberIds: readonly string[],
): Record<string, unknown> {
  return {
    title: input.title,
    note: input.note,
    date: input.date,
    startMinute: input.start,
    endMinute: input.start === null ? null : input.end,
    recurrence:
      input.repeat === null
        ? null
        : { frequency: input.repeat, interval: 1, weekdays: [weekdayOf(input.date)], until: null },
    memberIds: [...memberIds],
    createdBy,
  };
}
