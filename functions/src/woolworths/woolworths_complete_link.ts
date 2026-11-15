import { onCall } from 'firebase-functions/v2/https';

import { requireShopsPremiumForMember } from '../checkers/shops_premium';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { FirestoreWoolworthsLinkStore } from './firestore_woolworths_link_store';
import { WOOLWORTHS_SECRETS } from './woolworths_config';
import { completeWoolworthsLink } from './woolworths_link';
import {
  requireAddToWoolworths,
  woolworthsLoginHere,
  woolworthsSessionKeyHere,
} from './woolworths_runtime';
import { woolworthsCompleteLinkInput } from './woolworths_schemas';

export const woolworthsCompleteLink = onCall(
  { secrets: WOOLWORTHS_SECRETS, timeoutSeconds: 60 },
  async (request) => {
    const uid = requireUid(request.auth);
    const input = parseInput(woolworthsCompleteLinkInput, request.data);
    const store = db();
    await requireAddToWoolworths(store);
    await requireShopsPremiumForMember(store, uid);
    return completeWoolworthsLink(
      {
        links: new FirestoreWoolworthsLinkStore(store),
        login: woolworthsLoginHere(),
        key: woolworthsSessionKeyHere(),
        now: new Date(),
      },
      uid,
      input.refreshToken,
    );
  },
);
