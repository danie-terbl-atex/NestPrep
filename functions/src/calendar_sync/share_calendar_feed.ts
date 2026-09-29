import { onCall } from 'firebase-functions/v2/https';

import { db } from '../shared/firestore';
import { parseInput, requireUid } from '../household/parse_input';
import { callerIn } from './caller_access';
import { issueFeed, readCurrentFeed } from './feed_link';
import { householdInput } from './schemas';

/**
 * The household's feed link, made the first time anybody asks (calendar
 * ADR-0003). Any member may see it: it shows them the family week in their
 * own calendar, which is the point.
 */
export const shareCalendarFeed = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(householdInput, request.data);
  const store = db();
  await callerIn(store, input.householdId, uid);

  const url = await store.runTransaction(async (transaction) => {
    const current = await readCurrentFeed(transaction, store, input.householdId);
    if (current !== null) return current.url;
    return issueFeed(transaction, store, { householdId: input.householdId, uid, previous: null });
  });
  return { url };
});
