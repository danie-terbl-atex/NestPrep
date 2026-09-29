import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { verifyAndLinkPurchase } from './purchase_verification';
import { verifyPurchaseInput } from './schemas';
import { LiveStoreVerifiers } from './store_verifiers';
import { STORE_SECRETS, subscriptionConfig } from './subscription_config';

/**
 * The only way a household gets premium: the phone hands over what the store
 * gave it, and this asks the store whether it is real before writing the
 * entitlement (subscriptions ADR-0001). The client never writes its own
 * entitlement — the rules refuse it — so a purchase that does not pass here
 * gives nothing.
 *
 * Bound to the App Store key so it can ask Apple for renewal status; a kid
 * device is refused by `requireUid` before anything is read.
 */
export const verifyPurchase = onCall({ secrets: STORE_SECRETS }, async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(verifyPurchaseInput, request.data);
  const config = subscriptionConfig(true);
  return verifyAndLinkPurchase(
    { store: db(), config, verifiers: new LiveStoreVerifiers(config), now: () => new Date() },
    uid,
    input,
  );
});
