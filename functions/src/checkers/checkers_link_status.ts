import { onCall } from 'firebase-functions/v2/https';

import { requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { FirestoreLinkStore } from './firestore_link_store';
import { linkStatusOf } from './link_status';

/**
 * Whether the caller's Checkers account is linked, until when, and to which
 * number (the Checkers build contract). Reads only the caller's own link and
 * opens nothing sealed. Not behind the `addToCheckers` switch: with the switch
 * off it simply reports what is stored, so an app can still offer to unlink.
 */
export const checkersLinkStatus = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const link = await new FirestoreLinkStore(db()).read(uid);
  return linkStatusOf(link, new Date());
});
