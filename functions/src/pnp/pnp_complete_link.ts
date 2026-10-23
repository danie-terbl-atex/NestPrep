import { onCall } from 'firebase-functions/v2/https';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { FirestorePnpLinkStore } from './firestore_pnp_link_store';
import { PNP_SECRETS } from './pnp_config';
import { completePnpLink } from './pnp_link';
import { pnpHere, pnpSessionKeyHere, requireAddToPnp } from './pnp_runtime';
import { pnpCompleteLinkInput } from './pnp_schemas';

/**
 * Completes the member's Pick n Pay link with the code the app took from
 * PnP's redirect (add-to-pnp ADR-0003). The app relays only the code and the
 * state; the tokens PnP gives are sealed here and never sent back.
 */
export const pnpCompleteLink = onCall(
  { secrets: PNP_SECRETS, timeoutSeconds: 60 },
  async (request) => {
    const uid = requireUid(request.auth);
    const input = parseInput(pnpCompleteLinkInput, request.data);
    const store = db();
    await requireAddToPnp(store);
    return completePnpLink(
      {
        links: new FirestorePnpLinkStore(store),
        login: pnpHere().login,
        key: pnpSessionKeyHere(),
        now: new Date(),
      },
      uid,
      input,
    );
  },
);
