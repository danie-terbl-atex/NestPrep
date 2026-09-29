import { onSchedule } from 'firebase-functions/v2/scheduler';
import { SCHEDULER_REGION } from '../shared/region';

import { db } from '../shared/firestore';
import { runNotificationDelivery } from './notification_delivery';
import { pushService } from './push_service';

/**
 * Every five minutes: expiry reminders documents wrote, handovers a trigger
 * missed, and pushes that were waiting for somebody's quiet hours to end or
 * for FCM to come back (notifications ADR-0001). The body is
 * `runNotificationDelivery`, which the emulator suite drives directly.
 *
 * Every pass is idempotent, so a late or doubled run sends nothing twice
 * (BE-15); the timeout is its own and bounded (BE-19).
 */
export const deliverNotifications = onSchedule(
  {
    region: SCHEDULER_REGION,
    schedule: '*/5 * * * *',
    timeZone: 'UTC',
    timeoutSeconds: 240,
    retryCount: 0,
  },
  async () => {
    await runNotificationDelivery(db(), pushService(), new Date());
  },
);
