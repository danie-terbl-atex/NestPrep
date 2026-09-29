import { onCall } from 'firebase-functions/v2/https';

import { db } from '../shared/firestore';
import { parseInput, requireUid } from '../household/parse_input';
import { householdRef } from '../household/documents';
import { shiftOnlyMemberOf } from '../household/shift_window';
import { callerIn } from './caller_access';
import { refuseCalendarSync } from './errors';
import { issueFeed, readCurrentFeed } from './feed_link';
import { householdInput } from './schemas';

/**
 * The household's feed link, made the first time anybody asks (calendar
 * ADR-0003). Anybody the `calendar` grant lets see the week may see it: it shows them the family week in their
 * own calendar, which is the point.
 *
 * Not to a shift-only carer, on shift or off (nanny-hub ADR-0006): the feed is
 * a standing subscription that keeps answering after the shift ends, which is
 * exactly what shift-only exists to prevent.
 */
export const shareCalendarFeed = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(householdInput, request.data);
  const store = db();
  await callerIn(store, input.householdId, uid, 'view');
  const household = await householdRef(store, input.householdId).get();
  if (shiftOnlyMemberOf(household.data(), uid) !== null) {
    throw refuseCalendarSync('calendarNotShared');
  }

  const url = await store.runTransaction(async (transaction) => {
    const current = await readCurrentFeed(transaction, store, input.householdId);
    if (current !== null) return current.url;
    return issueFeed(transaction, store, { householdId: input.householdId, uid, previous: null });
  });
  return { url };
});
