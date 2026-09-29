import type { Firestore } from 'firebase-admin/firestore';

import { householdRef } from '../household/documents';
import { liveCalendarSources } from './calendar_sources';
import { FirestoreSyncStore } from './firestore_sync_store';
import { revokeBestEffort } from './revoke_best_effort';
import { type Provider, SYNCED_EVENTS, connectionRef, secretRef } from './sync_documents';

/** Imported events deleted per batch, and the most batches one removal will run. */
const BATCH_SIZE = 400;
const MAX_BATCHES = 10;

/**
 * Lets go of one connected calendar: the provider is told — best effort,
 * because a provider that is down must not keep a family's calendar connected
 * (calendar ADR-0003, BE-09) — its imported events go, then its credential and
 * the connection itself.
 *
 * The events go first and the connection last, so an interruption leaves a
 * connection that can simply be removed again (BE-07). Disconnecting and
 * erasing an account both end here (`ENG-01`, accounts ADR-0006).
 */
export async function removeCalendarConnection(
  store: Firestore,
  target: { householdId: string; connectionId: string; provider: Provider },
): Promise<number> {
  const credential = await new FirestoreSyncStore(store).readCredential(target.connectionId);
  const source = liveCalendarSources(false).source(target.provider);
  if (credential !== null && source !== null) {
    await revokeBestEffort(source, credential, target.provider);
  }

  const removed = await deleteImportedEvents(store, target.householdId, target.connectionId);
  const batch = store.batch();
  batch.delete(connectionRef(store, target.householdId, target.connectionId));
  batch.delete(secretRef(store, target.connectionId));
  await batch.commit();
  return removed;
}

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
