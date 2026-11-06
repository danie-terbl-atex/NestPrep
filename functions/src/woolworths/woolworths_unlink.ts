import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { FirestoreWoolworthsLinkStore } from './firestore_woolworths_link_store';

export const woolworthsUnlink = onCall(async (request) => {
  const uid = requireUid(request.auth);
  await new FirestoreWoolworthsLinkStore(db()).remove(uid);
  logger.info('woolworths link removed', { uid });
  return {};
});
