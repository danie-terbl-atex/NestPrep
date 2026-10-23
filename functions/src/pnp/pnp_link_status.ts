import { onCall } from 'firebase-functions/v2/https';

import { requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { FirestorePnpLinkStore } from './firestore_pnp_link_store';
import { pnpLinkStatusOf } from './pnp_link_state';

/**
 * Whether the caller's Pick n Pay account is linked, and since when
 * (add-to-pnp ADR-0003). Reads only the caller's own link and opens nothing
 * sealed. Not behind the `addToPnp` switch, so an app can always offer to
 * unlink.
 */
export const pnpLinkStatus = onCall(async (request) => {
  const uid = requireUid(request.auth);
  return pnpLinkStatusOf(await new FirestorePnpLinkStore(db()).read(uid));
});
