import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { db } from '../shared/firestore';
import { parseInput, requireUid } from '../household/parse_input';
import { type Caller, callerIn } from './caller_access';
import { refuseCalendarSync } from './errors';
import {
  type ExternalOccurrence,
  type OccurrenceTime,
  overlapsWindow,
  syncWindow,
} from './external_occurrence';
import { FirestoreSyncStore } from './firestore_sync_store';
import { type DeviceOccurrence, pushAppleCalendarInput } from './schemas';
import { connectionRef } from './sync_documents';
import { applyOccurrences } from './sync_engine';
import type { StoredConnection } from './sync_store';
import { knownZoneOr } from './zoned_time';

/**
 * The member's Apple Calendar, pushed from their iPhone. Apple has no
 * calendar API, so the phone reads EventKit — every calendar on it, iCloud
 * and any Google or Exchange account added in Settings — and hands the
 * occurrences here, where the same engine as every other source puts them on
 * the household's clock and writes only what changed.
 *
 * One connection per member, with no credential, so the scheduler never
 * touches it. `link: false` never makes one: a phone whose connection was
 * disconnected elsewhere is told so, and forgets its link.
 */
export const pushAppleCalendar = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(pushAppleCalendarInput, request.data);
  const store = db();
  const caller = await callerIn(store, input.householdId, uid, 'edit');
  const syncStore = new FirestoreSyncStore(store);

  const connection = await appleConnectionFor(store, syncStore, caller, input);
  const zone = knownZoneOr((await syncStore.readHouseholdZone(input.householdId)) ?? undefined);
  const occurrences = inWindow(input.occurrences, zone, new Date());
  const result = await applyOccurrences(
    syncStore,
    input.householdId,
    connection,
    occurrences,
    zone,
  );
  logger.info('apple calendar pushed', {
    connectionId: connection.id,
    sent: input.occurrences.length,
    kept: occurrences.length,
  });
  return { connectionId: connection.id, status: result.status, eventCount: result.eventCount };
});

export function appleConnectionId(memberId: string): string {
  return `apple_${memberId}`;
}

async function appleConnectionFor(
  store: Firestore,
  syncStore: FirestoreSyncStore,
  caller: Caller,
  input: { readonly householdId: string; readonly link: boolean },
): Promise<StoredConnection> {
  const connectionId = appleConnectionId(caller.memberId);
  const ref = connectionRef(store, input.householdId, connectionId);
  await store.runTransaction(async (transaction) => {
    if ((await transaction.get(ref)).exists) return;
    if (!input.link) throw refuseCalendarSync('connectionNotFound');
    transaction.create(ref, {
      provider: 'apple',
      memberId: caller.memberId,
      ownerUid: caller.uid,
      accountLabel: '',
      status: 'connected',
      eventCount: 0,
      lastSyncedAt: null,
      lastAttemptAt: null,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  const connection = await syncStore.readConnection(input.householdId, connectionId);
  if (connection === null) throw refuseCalendarSync('connectionNotFound');
  if (connection.ownerUid !== caller.uid) throw refuseCalendarSync('notYourConnection');
  return connection;
}

/** The phone's occurrences as the engine takes them, inside the household's window. */
export function inWindow(
  occurrences: readonly DeviceOccurrence[],
  zone: string,
  now: Date,
): ExternalOccurrence[] {
  const window = syncWindow(zone, now);
  return occurrences.flatMap((occurrence) => {
    const time = timeOf(occurrence);
    if (time === null || !overlapsWindow(time, window)) return [];
    return [{ externalId: occurrence.id, title: occurrence.title, time }];
  });
}

function timeOf(occurrence: DeviceOccurrence): OccurrenceTime | null {
  if (occurrence.allDay) {
    if (occurrence.endDateExclusive <= occurrence.startDate) return null;
    return {
      kind: 'allDay',
      startDate: occurrence.startDate,
      endDateExclusive: occurrence.endDateExclusive,
    };
  }
  if (occurrence.end < occurrence.start) return null;
  return { kind: 'timed', start: new Date(occurrence.start), end: new Date(occurrence.end) };
}
