import { onSchedule } from 'firebase-functions/v2/scheduler';

import { db } from '../shared/firestore';
import { runMorningDigest } from './morning_digest';
import { pushService } from './push_service';

/**
 * Every fifteen minutes, the morning digests that have come due somewhere in
 * the world (notifications ADR-0002). The body is `runMorningDigest`, which
 * the emulator suite drives with a fixed clock.
 *
 * No retry: the next run, fifteen minutes later, looks back one slot and
 * catches whatever this one missed, and a digest already sent is never sent
 * again (BE-15). The timeout is its own, because a run is many households'
 * reads rather than one person's request (BE-19).
 */
export const composeMorningDigests = onSchedule(
  { schedule: '*/15 * * * *', timeZone: 'UTC', timeoutSeconds: 300, retryCount: 0 },
  async () => {
    await runMorningDigest({ store: db(), sender: pushService(), now: new Date() });
  },
);
