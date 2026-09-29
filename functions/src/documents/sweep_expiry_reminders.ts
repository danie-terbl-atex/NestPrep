import { onSchedule } from 'firebase-functions/v2/scheduler';

import { db } from '../shared/firestore';
import { runExpirySweep } from './expiry_sweep';

/**
 * Once a day, the expiry reminders that have come due (documents ADR-0005).
 *
 * The job only *writes* reminders into `households/{h}/expiryReminders`; the
 * notifications feature delivers them. The body is `runExpirySweep`, which the
 * emulator suite runs directly because a schedule cannot be triggered there.
 *
 * Its timeout is its own rather than the callables' thirty seconds: a sweep of
 * 25 pages in two collection groups is longer work than one person's request,
 * and still bounded (BE-15, BE-19). One retry, because a sweep is idempotent.
 */
export const sweepExpiryReminders = onSchedule(
  {
    schedule: '0 5 * * *',
    timeZone: 'Africa/Johannesburg',
    timeoutSeconds: 120,
    retryCount: 1,
  },
  async () => {
    await runExpirySweep(db(), new Date());
  },
);
