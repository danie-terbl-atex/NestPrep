import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { STORE_PURCHASES, storedPurchase } from './subscription_documents';
import { applyToRecord, type NotificationDeps } from './store_notifications';
import { PurchaseRejected, StoreUnreachable } from './verified_purchase';

/**
 * The daily safety net under the stores' notifications (subscriptions
 * ADR-0001, BE-15): every linked subscription whose paid time ends between
 * three days ago and tomorrow is asked about again, so a renewal whose
 * notification was lost does not cost a family premium, and a lapse whose
 * notification was lost does not leave premium on.
 *
 * Bounded to one page, oldest first, and idempotent — it records what the
 * store says now, so running it twice or late changes nothing. A store that
 * cannot be asked costs only that subscription this run.
 */
export const RECONCILE_BATCH = 30;
const LOOK_BACK_MS = 3 * 24 * 60 * 60 * 1000;
const LOOK_AHEAD_MS = 24 * 60 * 60 * 1000;

export interface ReconcileSummary {
  readonly checked: number;
  readonly refreshed: number;
  readonly failed: number;
}

export async function runReconcile(deps: NotificationDeps): Promise<ReconcileSummary> {
  const now = deps.now().getTime();
  const due = await deps.store
    .collection(STORE_PURCHASES)
    .where('accessUntil', '>=', Timestamp.fromMillis(now - LOOK_BACK_MS))
    .where('accessUntil', '<=', Timestamp.fromMillis(now + LOOK_AHEAD_MS))
    .orderBy('accessUntil')
    .limit(RECONCILE_BATCH)
    .get();

  let refreshed = 0;
  let failed = 0;
  for (const doc of due.docs) {
    const parsed = storedPurchase.safeParse(doc.data());
    if (!parsed.success || parsed.data.householdId === null || parsed.data.supersededBy !== null) {
      continue;
    }
    const { store, storeRef, isTest } = parsed.data;
    try {
      const latest = await deps.verifiers.refresh(store, storeRef, isTest);
      if (latest === null) continue;
      await applyToRecord(deps, latest);
      refreshed += 1;
    } catch (error) {
      if (!(error instanceof StoreUnreachable) && !(error instanceof PurchaseRejected)) throw error;
      failed += 1;
      logger.warn('reconcile could not ask the store', { store, why: error.why });
    }
  }
  const summary = { checked: due.size, refreshed, failed };
  logger.info('subscriptions reconciled', summary);
  return summary;
}
