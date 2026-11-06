import { onCall } from 'firebase-functions/v2/https';

import { FirestoreGroceryLines } from '../cart_push/grocery_lines';
import { mayReadGroceries } from '../cart_push/grocery_reader';
import { householdRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { isOffShift } from '../household/shift_window';
import { db } from '../shared/firestore';
import { FirestoreWoolworthsLinkStore } from './firestore_woolworths_link_store';
import { pushToWoolworthsCart } from './woolworths_cart_push';
import { WOOLWORTHS_SECRETS } from './woolworths_config';
import { refuseWoolworths } from './woolworths_errors';
import {
  requireAddToWoolworths,
  woolworthsHere,
  woolworthsSessionKeyHere,
} from './woolworths_runtime';
import { woolworthsPushToCartInput } from './woolworths_schemas';

export const woolworthsPushToCart = onCall(
  { secrets: WOOLWORTHS_SECRETS, timeoutSeconds: 120 },
  async (request) => {
    const uid = requireUid(request.auth);
    const input = parseInput(woolworthsPushToCartInput, request.data);
    const store = db();
    const household = await householdRef(store, input.householdId).get();
    if (!household.exists || !mayReadGroceries(household.data(), uid)) {
      throw refuseWoolworths('not-a-member');
    }
    // A shift-only carer off shift holds nothing of the household (nanny-hub ADR-0006).
    if (await isOffShift(store, input.householdId, household.data(), uid, new Date())) {
      throw refuseWoolworths('not-a-member');
    }
    await requireAddToWoolworths(store);
    const woolworths = woolworthsHere();
    return pushToWoolworthsCart(
      {
        links: new FirestoreWoolworthsLinkStore(store),
        login: woolworths.login,
        shop: woolworths.shop,
        groceries: new FirestoreGroceryLines(store),
        key: woolworthsSessionKeyHere(),
        now: new Date(),
      },
      {
        uid,
        householdId: input.householdId,
        itemIds: input.itemIds,
        quantities: input.quantities ?? {},
      },
    );
  },
);
