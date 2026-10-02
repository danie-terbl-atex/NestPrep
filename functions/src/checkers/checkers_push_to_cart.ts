import { onCall } from 'firebase-functions/v2/https';

import { householdRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { isOffShift } from '../household/shift_window';
import { db } from '../shared/firestore';
import { pushToCheckersCart } from './cart_push';
import { requireGroceryReader } from './checkers_caller';
import { CHECKERS_SECRETS } from './checkers_config';
import { checkersHere, requireAddToCheckers, sessionKeyHere } from './checkers_runtime';
import { refuseCheckers } from './errors';
import { FirestoreLinkStore } from './firestore_link_store';
import { FirestoreGroceryLines } from './grocery_lines';
import { checkersPushToCartInput } from './schemas';

/**
 * "Add to Checkers": the list's matched, unbought items into the caller's own
 * Sixty60 cart (the Checkers build contract). Cart only — never a slot, a
 * checkout or a payment. The caller must be able to see the list; the items
 * and every product are read by the server, never taken from the request.
 */
export const checkersPushToCart = onCall(
  { secrets: CHECKERS_SECRETS, timeoutSeconds: 60 },
  async (request) => {
    const uid = requireUid(request.auth);
    const input = parseInput(checkersPushToCartInput, request.data);
    const store = db();
    const household = await householdRef(store, input.householdId).get();
    if (!household.exists) throw refuseCheckers('not-a-member');
    requireGroceryReader(household.data(), uid);
    // A shift-only carer off shift holds nothing of the household (nanny-hub ADR-0006).
    if (await isOffShift(store, input.householdId, household.data(), uid, new Date())) {
      throw refuseCheckers('not-a-member');
    }
    await requireAddToCheckers(store);
    return pushToCheckersCart(
      {
        links: new FirestoreLinkStore(store),
        shop: checkersHere().shop,
        groceries: new FirestoreGroceryLines(store),
        key: sessionKeyHere(),
        now: new Date(),
      },
      { uid, householdId: input.householdId, itemIds: input.itemIds },
    );
  },
);
