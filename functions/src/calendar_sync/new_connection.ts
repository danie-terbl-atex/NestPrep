import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { CALENDAR_CONNECTIONS, type Provider, secretRef } from './sync_documents';
import { householdRef } from '../household/documents';

export interface NewConnection {
  readonly householdId: string;
  readonly provider: Provider;
  readonly memberId: string;
  readonly ownerUid: string;
  readonly accountLabel: string;
  readonly credential: string;
}

/**
 * Files a new connection: what the household may see, and beside it — in the
 * same batch, so neither exists without the other (BE-07) — the credential
 * only a Function may read (calendar ADR-0003).
 */
export async function createConnection(
  store: Firestore,
  connection: NewConnection,
): Promise<string> {
  const ref = householdRef(store, connection.householdId).collection(CALENDAR_CONNECTIONS).doc();
  const now = FieldValue.serverTimestamp();
  const batch = store.batch();
  batch.set(ref, {
    provider: connection.provider,
    memberId: connection.memberId,
    ownerUid: connection.ownerUid,
    accountLabel: connection.accountLabel,
    status: 'connected',
    eventCount: 0,
    lastSyncedAt: null,
    lastAttemptAt: null,
    createdAt: now,
  });
  batch.set(secretRef(store, ref.id), {
    householdId: connection.householdId,
    provider: connection.provider,
    credential: connection.credential,
    lastAttemptAt: null,
  });
  await batch.commit();
  return ref.id;
}
