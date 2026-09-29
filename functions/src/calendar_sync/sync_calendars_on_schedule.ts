import type { Firestore } from 'firebase-admin/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { db } from '../shared/firestore';
import { liveCalendarSources } from './calendar_sources';
import { FirestoreSyncStore } from './firestore_sync_store';
import { CONNECTION_SECRETS, secretRef } from './sync_documents';
import { PROVIDER_SECRETS } from './sync_config';
import { type SyncDeps, syncConnection } from './sync_engine';

/**
 * Every 30 minutes, the connections tried longest ago are synced again
 * (calendar ADR-0003, BE-15). Bounded three ways: at most [BATCH] connections,
 * [CONCURRENCY] at a time, and no new wave once [BUDGET_MS] of the 30-second
 * limit is spent. Idempotent — a connection synced twice writes nothing the
 * second time — and safe to run late, because it simply picks up whoever has
 * waited longest.
 */
export const BATCH = 20;
export const CONCURRENCY = 5;
export const BUDGET_MS = 20_000;

const secretShape = z.object({ householdId: z.string() });

export const syncCalendarsOnSchedule = onSchedule(
  { schedule: 'every 30 minutes', secrets: PROVIDER_SECRETS },
  async () => {
    const store = db();
    const summary = await syncOldestConnections(store, {
      store: new FirestoreSyncStore(store),
      sources: liveCalendarSources(true),
      now: () => new Date(),
    });
    logger.info('scheduled calendar sync', summary);
  },
);

export async function syncOldestConnections(
  store: Firestore,
  deps: SyncDeps,
): Promise<{ attempted: number; failed: number; orphans: number }> {
  const started = Date.now();
  const due = await store
    .collection(CONNECTION_SECRETS)
    .orderBy('lastAttemptAt')
    .limit(BATCH)
    .get();
  let attempted = 0;
  let failed = 0;
  let orphans = 0;

  for (let start = 0; start < due.docs.length; start += CONCURRENCY) {
    if (Date.now() - started > BUDGET_MS) break;
    const wave = due.docs.slice(start, start + CONCURRENCY);
    const results = await Promise.allSettled(
      wave.map(async (doc) => {
        const secret = secretShape.safeParse(doc.data());
        const result = secret.success
          ? await syncConnection(deps, secret.data.householdId, doc.id)
          : null;
        // A credential whose connection has gone is of no use to anybody, and
        // left here it would sit at the front of this queue for ever.
        if (result === null) {
          const batch = store.batch();
          batch.delete(secretRef(store, doc.id));
          await batch.commit();
          orphans++;
        }
      }),
    );
    attempted += wave.length;
    for (const result of results) {
      if (result.status === 'rejected') {
        failed++;
        logger.error('scheduled calendar sync failed', { error: String(result.reason) });
      }
    }
  }
  return { attempted, failed, orphans };
}
