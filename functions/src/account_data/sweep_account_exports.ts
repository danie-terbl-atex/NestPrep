import { logger } from 'firebase-functions/v2';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { SCHEDULER_REGION } from '../shared/region';

import { objectStore } from '../shared/storage';
import { sweepExpiredExports } from './export_files';

/**
 * Every hour, the data exports whose hour is up (accounts ADR-0006). The body
 * is `sweepExpiredExports`, which the unit tests drive with a fake store.
 * One retry, because a sweep is idempotent (BE-15).
 */
export const sweepAccountExports = onSchedule(
  {
    region: SCHEDULER_REGION,
    schedule: '20 * * * *',
    timeZone: 'Africa/Johannesburg',
    timeoutSeconds: 120,
    retryCount: 1,
  },
  async () => {
    const removed = await sweepExpiredExports(objectStore(), new Date());
    logger.info('expired account exports removed', { removed });
  },
);
