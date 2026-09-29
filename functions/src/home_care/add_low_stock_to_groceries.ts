import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { HOUSEHOLDS, householdRef } from '../household/documents';
import { LAUNCH_TIME_ZONE, weekKeyOf } from '../product_analytics/iso_week';
import { readFlag } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { HOME_CARE_PRODUCTS, groceryItems } from './home_care_refs';
import { groceryLineId, normalisedName, restockFor } from './restock_decision';

/** The reason the list shows — the app's `HomeCareStockCopy.runningOut`. */
export const RUNNING_LOW = 'Running low';

/** How much of the list is read to look for the same name — groceries' own bound. */
const LIST_LIMIT = 200;

/**
 * A product marked low or out goes onto the household's grocery list, once
 * (home-care ADR-0005).
 *
 * A trigger rather than the phone, because the helper who notices is often
 * offline and may hold only `view` on groceries: her stock mark is hers to
 * write, and the line is written here on the household's behalf with her name
 * on it. In one transaction the list is read and, unless an unbought line with
 * the same normalised name is already there, `groceryItems/homeCare-{id}` is
 * written — so a retried trigger, or low then out, adds one line. A grocery
 * write that fails never undoes the stock mark (BE-09).
 *
 * It is written as a **planned item**, the groceries feature's one way of
 * saying where a line nobody typed came from (groceries ADR-0002): the
 * normalised name, the household's week, and the reason shown. The app's
 * `HomeCareStockGrocerySource` asks for the same line while the product is
 * low, so *keep in step* keeps it and a person's edit adopts it.
 */
export const addLowStockToGroceries = onDocumentWritten(
  `${HOUSEHOLDS}/{householdId}/${HOME_CARE_PRODUCTS}/{productId}`,
  async (event) => {
    const { householdId, productId } = event.params;
    const restock = restockFor(event.data?.before.data(), event.data?.after.data());
    if (restock === null) return;
    const store = db();
    if (!(await readFlag(store, 'homeCareStock'))) return;

    const list = groceryItems(store, householdId);
    const added = await store.runTransaction(async (transaction) => {
      const household = await transaction.get(householdRef(store, householdId));
      const zone: unknown = household.get('timeZone');
      const items = await transaction.get(list.limit(LIST_LIMIT));
      const key = normalisedName(restock.name);
      const alreadyThere = items.docs.some((item) => {
        const name: unknown = item.get('name');
        const boughtBy: unknown = item.get('boughtBy');
        return (
          (boughtBy === null || boughtBy === undefined) &&
          typeof name === 'string' &&
          normalisedName(name) === key
        );
      });
      if (alreadyThere) return false;
      transaction.set(list.doc(groceryLineId(productId)), {
        name: restock.name,
        quantity: null,
        addedBy: restock.markedBy,
        addedAt: FieldValue.serverTimestamp(),
        boughtAt: null,
        boughtBy: null,
        sourceKey: key,
        sourceWeek: weekKeyOf(new Date(), typeof zone === 'string' ? zone : LAUNCH_TIME_ZONE),
        sourceNote: RUNNING_LOW,
      });
      return true;
    });

    // Ids only — never the product's name, which is the household's (ENG-22).
    logger.info('low stock checked against the grocery list', { householdId, productId, added });
  },
);
