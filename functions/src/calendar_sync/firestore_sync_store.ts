import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { householdRef } from '../household/documents';
import {
  CONNECTION_STATUSES,
  PROVIDERS,
  SYNCED_EVENTS,
  connectionRef,
  secretRef,
  syncedEventRef,
} from './sync_documents';
import type { StoredConnection, SyncChanges, SyncStore } from './sync_store';

/**
 * The sync store on Firestore. Every document read is parsed rather than cast
 * (ENG-09), and every write goes through a batch — the changes of one sync
 * land in chunks of 400, each chunk atomic, and a sync interrupted halfway is
 * finished by the next one because the fingerprints say what is still to do
 * (BE-07).
 */
const connectionShape = z.object({
  provider: z.enum(PROVIDERS),
  memberId: z.string(),
  ownerUid: z.string(),
  accountLabel: z.string().default(''),
  status: z.enum(CONNECTION_STATUSES).catch('connected'),
  eventCount: z.number().int().nonnegative().catch(0),
});

const householdShape = z.object({ timeZone: z.string() });
const credentialShape = z.object({ credential: z.string().min(1) });
const fingerprintShape = z.object({ fingerprint: z.string() });

const BATCH_SIZE = 400;
const MAX_EXISTING = 2_000;

export class FirestoreSyncStore implements SyncStore {
  constructor(private readonly store: Firestore) {}

  async readConnection(
    householdId: string,
    connectionId: string,
  ): Promise<StoredConnection | null> {
    const snapshot = await connectionRef(this.store, householdId, connectionId).get();
    const parsed = connectionShape.safeParse(snapshot.data());
    if (!snapshot.exists || !parsed.success) return null;
    return { ...parsed.data, id: connectionId, householdId };
  }

  async readHouseholdZone(householdId: string): Promise<string | null> {
    const snapshot = await householdRef(this.store, householdId).get();
    const parsed = householdShape.safeParse(snapshot.data());
    return parsed.success ? parsed.data.timeZone : null;
  }

  async readCredential(connectionId: string): Promise<string | null> {
    const parsed = credentialShape.safeParse(
      (await secretRef(this.store, connectionId).get()).data(),
    );
    return parsed.success ? parsed.data.credential : null;
  }

  async saveCredential(connectionId: string, credential: string): Promise<void> {
    const batch = this.store.batch();
    batch.update(secretRef(this.store, connectionId), { credential });
    await batch.commit();
  }

  async readFingerprints(householdId: string, connectionId: string): Promise<Map<string, string>> {
    const snapshot = await householdRef(this.store, householdId)
      .collection(SYNCED_EVENTS)
      .where('connectionId', '==', connectionId)
      .select('fingerprint')
      .limit(MAX_EXISTING)
      .get();
    return new Map(
      snapshot.docs.map((doc) => {
        const parsed = fingerprintShape.safeParse(doc.data());
        return [doc.id, parsed.success ? parsed.data.fingerprint : ''];
      }),
    );
  }

  async applyChanges(householdId: string, changes: SyncChanges): Promise<void> {
    const operations = [
      ...changes.upserts.map((upsert) => ({ kind: 'upsert' as const, ...upsert })),
      ...changes.deletes.map((id) => ({ kind: 'delete' as const, id })),
    ];
    for (let start = 0; start < operations.length; start += BATCH_SIZE) {
      const batch = this.store.batch();
      for (const operation of operations.slice(start, start + BATCH_SIZE)) {
        const ref = syncedEventRef(this.store, householdId, operation.id);
        if (operation.kind === 'delete') batch.delete(ref);
        else batch.set(ref, { ...operation.document, syncedAt: FieldValue.serverTimestamp() });
      }
      await batch.commit();
    }
  }

  async recordOutcome(
    householdId: string,
    connectionId: string,
    outcome: Parameters<SyncStore['recordOutcome']>[2],
  ): Promise<void> {
    const now = FieldValue.serverTimestamp();
    const batch = this.store.batch();
    batch.update(connectionRef(this.store, householdId, connectionId), {
      status: outcome.status,
      lastAttemptAt: now,
      ...(outcome.status === 'connected'
        ? { lastSyncedAt: now, eventCount: outcome.eventCount ?? 0 }
        : {}),
    });
    // The scheduler picks the connections tried longest ago from here, because
    // this collection is top-level and needs no collection-group query (BE-08).
    batch.set(secretRef(this.store, connectionId), { lastAttemptAt: now }, { merge: true });
    await batch.commit();
  }
}
