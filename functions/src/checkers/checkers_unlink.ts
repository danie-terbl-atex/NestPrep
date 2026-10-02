import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { FirestoreLinkStore } from './firestore_link_store';

/**
 * Forgets the caller's Checkers link — session, identifiers, number, pending
 * code — by deleting the document (the Checkers build contract). Not behind
 * the `addToCheckers` switch: switching the feature off must never trap a
 * member's session on the server. Nothing is sent to Checkers; the session
 * lapses there within the hour.
 */
export const checkersUnlink = onCall(async (request) => {
  const uid = requireUid(request.auth);
  await new FirestoreLinkStore(db()).remove(uid);
  logger.info('checkers link removed', { uid });
  return { linked: false };
});
