import { onCall } from 'firebase-functions/v2/https';

import { requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { FirestoreWoolworthsLinkStore } from './firestore_woolworths_link_store';
import { woolworthsLinkStatusOf } from './woolworths_link';

export const woolworthsLinkStatus = onCall(async (request) => {
  const uid = requireUid(request.auth);
  return woolworthsLinkStatusOf(await new FirestoreWoolworthsLinkStore(db()).read(uid));
});
