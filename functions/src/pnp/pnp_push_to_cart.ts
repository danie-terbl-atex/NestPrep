import { onCall } from 'firebase-functions/v2/https';

import { FirestoreGroceryLines } from '../cart_push/grocery_lines';
import { mayReadGroceries } from '../cart_push/grocery_reader';
import { householdRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { isOffShift } from '../household/shift_window';
import { db } from '../shared/firestore';
import { FirestorePnpLinkStore } from './firestore_pnp_link_store';
import { pushToPnpCart } from './pnp_cart_push';
import { PNP_SECRETS } from './pnp_config';
import { refusePnp } from './pnp_errors';
import { pnpHere, pnpSessionKeyHere, requireAddToPnp } from './pnp_runtime';
import { pnpPushToCartInput } from './pnp_schemas';

/**
 * "Add to my Pick n Pay cart": the list's PnP-matched, unbought items into
 * the caller's own PnP cart, as many packs as asked (add-to-pnp ADR-0004).
 * Cart only. The caller must be able to see the list; the items and every
 * product are read by the server, never taken from the request.
 */
export const pnpPushToCart = onCall(
  { secrets: PNP_SECRETS, timeoutSeconds: 120 },
  async (request) => {
    const uid = requireUid(request.auth);
    const input = parseInput(pnpPushToCartInput, request.data);
    const store = db();
    const household = await householdRef(store, input.householdId).get();
    if (!household.exists || !mayReadGroceries(household.data(), uid)) {
      throw refusePnp('not-a-member');
    }
    // A shift-only carer off shift holds nothing of the household (nanny-hub ADR-0006).
    if (await isOffShift(store, input.householdId, household.data(), uid, new Date())) {
      throw refusePnp('not-a-member');
    }
    await requireAddToPnp(store);
    const pnp = pnpHere();
    return pushToPnpCart(
      {
        links: new FirestorePnpLinkStore(store),
        login: pnp.login,
        shop: pnp.shop,
        groceries: new FirestoreGroceryLines(store),
        key: pnpSessionKeyHere(),
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
