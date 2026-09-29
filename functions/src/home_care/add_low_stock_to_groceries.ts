import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { HOUSEHOLDS } from '../household/documents';
import { readFlag } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { HOME_CARE_PRODUCTS, groceryItems } from './home_care_refs';
import { groceryLineId, normalisedName, restockFor } from './restock_decision';

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
 * written with `source: 'homeCare'` — so a retried trigger, or low then out,
 * adds one line. A grocery write that fails never undoes the stock mark
 * (BE-09).
 *
 * When groceries phase 2's `GrocerySuggestionSource` lands, this is home
 * care's source; `source`/`sourceId` are the provenance it will map.
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
        source: 'homeCare',
        sourceId: productId,
      });
      return true;
    });

    // Ids only — never the product's name, which is the household's (ENG-22).
    logger.info('low stock checked against the grocery list', { householdId, productId, added });
  },
);
