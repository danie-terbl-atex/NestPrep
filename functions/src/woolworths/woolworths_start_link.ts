import { onCall } from 'firebase-functions/v2/https';

import { requireShopsPremiumForMember } from '../checkers/shops_premium';
import { requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { requireAddToWoolworths, woolworthsCognitoHere } from './woolworths_runtime';

export const woolworthsStartLink = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const store = db();
  await requireAddToWoolworths(store);
  await requireShopsPremiumForMember(store, uid);
  const { clientId, region } = woolworthsCognitoHere();
  return { clientId, region };
});
