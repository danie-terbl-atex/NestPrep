import { onSchedule } from 'firebase-functions/v2/scheduler';
import { SCHEDULER_REGION } from '../shared/region';

import { db } from '../shared/firestore';
import { runReconcile } from './reconcile';
import { LiveStoreVerifiers } from './store_verifiers';
import { STORE_SECRETS, subscriptionConfig } from './subscription_config';

/**
 * Once a day, the subscriptions whose paid time is ending or has just ended
 * are asked about again (subscriptions ADR-0001). The body is `runReconcile`,
 * which the tests run directly because a schedule cannot be triggered there.
 *
 * Its timeout is its own: thirty store calls, each bounded at eight seconds,
 * is longer than one person's request and still bounded (BE-15, BE-19).
 */
export const reconcileSubscriptions = onSchedule(
  {
    region: SCHEDULER_REGION,
    schedule: '30 4 * * *',
    timeZone: 'Africa/Johannesburg',
    timeoutSeconds: 300,
    retryCount: 1,
    secrets: STORE_SECRETS,
  },
  async () => {
    const config = subscriptionConfig(true);
    await runReconcile({
      store: db(),
      config,
      verifiers: new LiveStoreVerifiers(config),
      now: () => new Date(),
    });
  },
);
