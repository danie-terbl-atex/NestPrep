import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { parseInput, requireUid } from '../household/parse_input';
import { liveCalendarSources } from './calendar_sources';
import { callerIn } from './caller_access';
import { refuseCalendarSync } from './errors';
import { FirestoreSyncStore } from './firestore_sync_store';
import { labelForLink } from './ics_calendar';
import { parseIcs } from './ics_parser';
import { normaliseCalendarLink } from './link_guard';
import { createConnection } from './new_connection';
import { connectCalendarLinkInput } from './schemas';
import { syncConnection } from './sync_engine';

/**
 * Connects a calendar by its link — Apple's way in, and any school's or club's
 * published calendar (calendar ADR-0003). The link is read once before it is
 * kept, so a pasted web page is refused in words now rather than failing
 * quietly every half hour.
 */
export const connectCalendarLink = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(connectCalendarLinkInput, request.data);
  const store = db();
  const caller = await callerIn(store, input.householdId, uid, 'edit');
  const sources = liveCalendarSources(false);

  const isEmulator = process.env['FUNCTIONS_EMULATOR'] === 'true';
  const link = normaliseCalendarLink(input.url, isEmulator);
  if (link === null) throw refuseCalendarSync('notACalendarLink');

  const download = await sources.ics.download(link.toString());
  if (download.kind === 'unreachable') throw refuseCalendarSync('calendarLinkUnreachable');
  if (download.kind === 'notACalendar' || parseIcs(download.text) === null) {
    throw refuseCalendarSync('notACalendarLink');
  }

  const connectionId = await createConnection(store, {
    householdId: input.householdId,
    provider: 'ics',
    memberId: caller.memberId,
    ownerUid: uid,
    accountLabel: labelForLink(link.toString()),
    credential: link.toString(),
  });
  const result = await syncConnection(
    { store: new FirestoreSyncStore(store), sources, now: () => new Date() },
    input.householdId,
    connectionId,
  );
  logger.info('calendar link connected', { connectionId });
  return {
    connectionId,
    status: result?.status ?? 'connected',
    eventCount: result?.eventCount ?? 0,
  };
});
