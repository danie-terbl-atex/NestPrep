import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { FirestorePnpLinkStore } from './firestore_pnp_link_store';

/**
 * Forgets the caller's Pick n Pay link — tokens and any pending start — by
 * deleting the document (add-to-pnp ADR-0003). Not behind the `addToPnp`
 * switch: switching the feature off must never trap a member's tokens on the
 * server. Nothing is sent to PnP; the refresh token is simply forgotten.
 */
export const pnpUnlink = onCall(async (request) => {
  const uid = requireUid(request.auth);
  await new FirestorePnpLinkStore(db()).remove(uid);
  logger.info('pnp link removed', { uid });
  return { linked: false };
});
