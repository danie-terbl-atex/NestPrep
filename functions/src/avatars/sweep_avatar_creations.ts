import { onSchedule } from 'firebase-functions/v2/scheduler';

import { FirestoreUsageLedger } from '../ai/firestore_usage_ledger';
import { db } from '../shared/firestore';
import { SCHEDULER_REGION } from '../shared/region';
import { objectStore } from '../shared/storage';
import { sweepStuckCreations } from './creation_sweep';

/**
 * Every hour, the creations a dead run left at `checking` or `drawing`
 * (avatars ADR-0003). The body is `sweepStuckCreations`, which the emulator
 * suite runs directly because a schedule cannot be triggered there. One
 * retry, because the sweep is idempotent (BE-15).
 */
export const sweepAvatarCreations = onSchedule(
  {
    region: SCHEDULER_REGION,
    schedule: '40 * * * *',
    timeZone: 'Africa/Johannesburg',
    timeoutSeconds: 120,
    retryCount: 1,
  },
  async () => {
    const store = db();
    await sweepStuckCreations(
      { store, objects: objectStore(), ledger: new FirestoreUsageLedger(store) },
      new Date(),
    );
  },
);
