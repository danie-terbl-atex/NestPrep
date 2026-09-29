import { onRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';

import { db } from '../shared/firestore';
import { applyAppStoreNotification } from './store_notifications';
import { LiveStoreVerifiers } from './store_verifiers';
import { STORE_SECRETS, subscriptionConfig } from './subscription_config';

/**
 * App Store Server Notifications v2 (subscriptions ADR-0001): the URL Daniel
 * pastes into App Store Connect for both production and sandbox. Apple posts
 * a signed payload; nothing in it is believed until its chain ends in Apple's
 * root. Anybody can reach this URL, so a body that does not verify is a 400
 * and nothing more — no detail about why.
 *
 * Apple retries anything that is not a 2xx, so a failure writing Firestore is
 * left to throw and become a 500, and the notification comes again.
 */
const body = z.object({ signedPayload: z.string().min(1).max(200_000) });

export const appStoreNotifications = onRequest({ secrets: STORE_SECRETS }, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('');
    return;
  }
  const parsed = body.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).send('');
    return;
  }
  const config = subscriptionConfig(true);
  const verifiers = new LiveStoreVerifiers(config);
  const answer = await applyAppStoreNotification(
    { store: db(), config, verifiers, now: () => new Date() },
    () => verifiers.apple.verifyNotification(parsed.data.signedPayload),
  );
  res.status(answer === 'accepted' ? 200 : 400).send('');
});
