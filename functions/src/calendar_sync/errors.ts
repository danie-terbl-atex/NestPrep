import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Every way a calendar sync call can refuse (calendar ADR-0003).
 *
 * Same contract as the household and documents refusals (BE-04): each carries
 * a `reason` the client maps to a sentence, and
 * `app/test/features/calendar_sync/data/calendar_sync_refusal_contract_test.dart`
 * reads this block. `notAMember` and `notAnAdmin` reuse the household's names
 * because that is what they are about.
 */
export const CALENDAR_SYNC_REFUSALS = {
  notAMember: ['permission-denied', 'You are not in this household.'],
  notAnAdmin: ['permission-denied', 'Only an admin can do that.'],
  // The household's grant does not give this member enough of the calendar
  // (household ADR-0003).
  calendarNotShared: ['permission-denied', 'The household has not shared the calendar that far.'],
  notYourConnection: [
    'permission-denied',
    'Only the person who connected it, or an admin, can do that.',
  ],
  connectionNotFound: ['not-found', 'That calendar is no longer connected.'],
  providerNotConfigured: ['failed-precondition', 'That provider is not set up yet.'],
  notACalendarLink: ['invalid-argument', 'That is not a calendar link NestPrep can read.'],
  calendarLinkUnreachable: ['unavailable', 'That calendar link could not be read.'],
} as const satisfies Record<string, readonly [FunctionsErrorCode, string]>;

export type CalendarSyncRefusal = keyof typeof CALENDAR_SYNC_REFUSALS;

/** The one place a calendar sync refusal becomes the error the client receives. */
export function refuseCalendarSync(reason: CalendarSyncRefusal): HttpsError {
  const [code, message] = CALENDAR_SYNC_REFUSALS[reason];
  return new HttpsError(code, message, { reason });
}
