import { onCall } from 'firebase-functions/v2/https';

import { requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { FirestorePnpLinkStore } from './firestore_pnp_link_store';
import { PNP_SECRETS } from './pnp_config';
import { startPnpLink } from './pnp_link';
import { pnpHere, pnpSessionKeyHere, requireAddToPnp } from './pnp_runtime';

/**
 * The URL of Pick n Pay's own login page for this member's link (add-to-pnp
 * ADR-0003); the PKCE verifier and state it was made with stay sealed here.
 */
export const pnpStartLink = onCall({ secrets: PNP_SECRETS }, async (request) => {
  const uid = requireUid(request.auth);
  const store = db();
  await requireAddToPnp(store);
  return startPnpLink(
    {
      links: new FirestorePnpLinkStore(store),
      login: pnpHere().login,
      key: pnpSessionKeyHere(),
      now: new Date(),
    },
    uid,
  );
});
