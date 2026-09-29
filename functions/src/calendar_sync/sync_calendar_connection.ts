import { onCall } from 'firebase-functions/v2/https';

import { db } from '../shared/firestore';
import { parseInput, requireUid } from '../household/parse_input';
import { liveCalendarSources } from './calendar_sources';
import { callerIn, mayManage } from './caller_access';
import { refuseCalendarSync } from './errors';
import { FirestoreSyncStore } from './firestore_sync_store';
import { connectionInput } from './schemas';
import { PROVIDER_SECRETS } from './sync_config';
import { syncConnection } from './sync_engine';

/**
 * "Sync now", by the person who connected the calendar or an admin
 * (calendar ADR-0003). Whatever happens is left on the connection as its
 * status, which is what the screen reads; the answer here only saves a read.
 */
export const syncCalendarConnection = onCall({ secrets: PROVIDER_SECRETS }, async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(connectionInput, request.data);
  const store = db();
  const caller = await callerIn(store, input.householdId, uid);
  const syncStore = new FirestoreSyncStore(store);

  const connection = await syncStore.readConnection(input.householdId, input.connectionId);
  if (connection === null) throw refuseCalendarSync('connectionNotFound');
  if (!mayManage(caller, connection)) throw refuseCalendarSync('notYourConnection');

  const result = await syncConnection(
    { store: syncStore, sources: liveCalendarSources(true), now: () => new Date() },
    input.householdId,
    input.connectionId,
  );
  if (result === null) throw refuseCalendarSync('connectionNotFound');
  return { status: result.status, eventCount: result.eventCount };
});
