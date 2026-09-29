import { onMessagePublished } from 'firebase-functions/v2/pubsub';

import { db } from '../shared/firestore';
import { applyPlayNotification } from './store_notifications';
import { LiveStoreVerifiers } from './store_verifiers';
import { subscriptionConfig } from './subscription_config';

/**
 * Google Play's Real-time Developer Notifications (subscriptions ADR-0001).
 * Deploying this creates the topic; Daniel points the Play Console's
 * *Monetisation setup* at `projects/nestprep-643b7/topics/play-billing` and
 * grants Google's publisher account the right to publish to it.
 *
 * Retried: a notification that fails because Google's API could not be asked
 * comes again rather than being lost, which is safe because applying one is
 * idempotent — it records what the store says now.
 */
export const PLAY_BILLING_TOPIC = 'play-billing';

export const playBillingNotifications = onMessagePublished(
  { topic: PLAY_BILLING_TOPIC, retry: true },
  async (event) => {
    const config = subscriptionConfig(false);
    await applyPlayNotification(
      { store: db(), config, verifiers: new LiveStoreVerifiers(config), now: () => new Date() },
      decoded(event.data.message.data),
    );
  },
);

/** The message body Google published, as JSON, or null when it is not JSON. */
function decoded(base64: string): unknown {
  try {
    return JSON.parse(Buffer.from(base64, 'base64').toString('utf8')) as unknown;
  } catch (error) {
    if (error instanceof SyntaxError) return null;
    throw error;
  }
}
