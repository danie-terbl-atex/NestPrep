import { onCall } from 'firebase-functions/v2/https';

import { requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { requireAddToWoolworths, woolworthsCognitoHere } from './woolworths_runtime';

export const woolworthsStartLink = onCall(async (request) => {
  requireUid(request.auth);
  await requireAddToWoolworths(db());
  const { clientId, region } = woolworthsCognitoHere();
  return { clientId, region };
});
