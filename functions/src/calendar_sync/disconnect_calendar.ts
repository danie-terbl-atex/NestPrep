import type { Firestore } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { householdRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { liveCalendarSources } from './calendar_sources';
import { callerIn, mayManage } from './caller_access';
import { refuseCalendarSync } from './errors';
import { FirestoreSyncStore } from './firestore_sync_store';
import { revokeBestEffort } from './revoke_best_effort';
import { connectionInput } from './schemas';
import { SYNCED_EVENTS, connectionRef, secretRef } from './sync_documents';

/** Imported events deleted per batch, and the most batches one call will run. */
const BATCH_SIZE = 400;
const MAX_BATCHES = 10;

/**
 * Disconnects a calendar: its imported events go, its credential goes, and
 * the provider is told — best effort, because a provider that is down must
 * not keep a family's calendar connected (calendar ADR-0003, BE-09).
 *
 * The events go first and the connection last, so an interruption leaves a
 * connection that can simply be disconnected again (BE-07).
 */
export const disconnectCalendar = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(connectionInput, request.data);
  const store = db();
  const caller = await callerIn(store, input.householdId, uid);
  const syncStore = new FirestoreSyncStore(store);

  const connection = await syncStore.readConnection(input.householdId, input.connectionId);
  if (connection === null) throw refuseCalendarSync('connectionNotFound');
  if (!mayManage(caller, connection)) throw refuseCalendarSync('notYourConnection');

  const credential = await syncStore.readCredential(input.connectionId);
  const source = liveCalendarSources(false).source(connection.provider);
  if (credential !== null && source !== null) {
    await revokeBestEffort(source, credential, connection.provider);
  }

  const removed = await deleteImportedEvents(store, input.householdId, input.connectionId);
  const batch = store.batch();
  batch.delete(connectionRef(store, input.householdId, input.connectionId));
  batch.delete(secretRef(store, input.connectionId));
  await batch.commit();

  logger.info('calendar disconnected', { connectionId: input.connectionId, removed });
  return { removed };
});

async function deleteImportedEvents(
  store: Firestore,
  householdId: string,
  connectionId: string,
): Promise<number> {
  let removed = 0;
  for (let round = 0; round < MAX_BATCHES; round++) {
    const page = await householdRef(store, householdId)
      .collection(SYNCED_EVENTS)
      .where('connectionId', '==', connectionId)
      .limit(BATCH_SIZE)
      .get();
    if (page.empty) break;
    const batch = store.batch();
    for (const doc of page.docs) batch.delete(doc.ref);
    await batch.commit();
    removed += page.size;
  }
  return removed;
}
