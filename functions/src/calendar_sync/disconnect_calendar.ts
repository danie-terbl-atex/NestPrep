import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { parseInput, requireUid } from '../household/parse_input';
import { callerIn, mayManage } from './caller_access';
import { refuseCalendarSync } from './errors';
import { FirestoreSyncStore } from './firestore_sync_store';
import { removeCalendarConnection } from './remove_connection';
import { connectionInput } from './schemas';

/**
 * Disconnects a calendar: its imported events go, its credential goes, and
 * the provider is told — best effort (calendar ADR-0003, BE-09). The work is
 * `removeCalendarConnection`, which erasing an account shares (`ENG-01`).
 */
export const disconnectCalendar = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(connectionInput, request.data);
  const store = db();
  const caller = await callerIn(store, input.householdId, uid, 'edit');

  const connection = await new FirestoreSyncStore(store).readConnection(
    input.householdId,
    input.connectionId,
  );
  if (connection === null) throw refuseCalendarSync('connectionNotFound');
  if (!mayManage(caller, connection)) throw refuseCalendarSync('notYourConnection');

  const removed = await removeCalendarConnection(store, {
    householdId: input.householdId,
    connectionId: input.connectionId,
    provider: connection.provider,
  });

  logger.info('calendar disconnected', { connectionId: input.connectionId, removed });
  return { removed };
});
