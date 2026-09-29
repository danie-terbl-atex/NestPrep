import { onCall } from 'firebase-functions/v2/https';

import { db } from '../shared/firestore';
import { parseInput, requireUid } from '../household/parse_input';
import { callerIn } from './caller_access';
import { refuseCalendarSync } from './errors';
import { issueFeed, readCurrentFeed } from './feed_link';
import { householdInput } from './schemas';

/**
 * A new feed link, and the old one stops working — for when a link has been
 * shared further than it should have been. An admin's call (calendar ADR-0003).
 */
export const resetCalendarFeed = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(householdInput, request.data);
  const store = db();
  const caller = await callerIn(store, input.householdId, uid);
  if (caller.role !== 'admin') throw refuseCalendarSync('notAnAdmin');

  const url = await store.runTransaction(async (transaction) => {
    const previous = await readCurrentFeed(transaction, store, input.householdId);
    return issueFeed(transaction, store, { householdId: input.householdId, uid, previous });
  });
  return { url };
});
