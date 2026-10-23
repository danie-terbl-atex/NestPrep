import type { GroceryLine } from './grocery_lines';
import type { Skipped, Wanted } from './push_outcome';

/** The shop a push fills, as the sort needs it. */
export interface PushingShop {
  /** As stored in `productMatch.retailer`. */
  readonly retailer: string;
  /** Whether a pick's unit is sold by weight, which no push guesses a weight for. */
  readonly isWeighedUnit: (unitOfMeasure: string) => boolean;
}

/**
 * The items worth asking the shop about, decided without the shop or
 * Firestore. An item that is gone or already bought is `not-found` — it is no
 * longer on the list to buy; one with no pick, or a pick at another shop, is
 * `no-match`; a weighed pick is `weighed-item`.
 */
export function sortPushedItems(
  itemIds: readonly string[],
  lines: Readonly<Record<string, GroceryLine>>,
  shop: PushingShop,
): { wanted: Wanted[]; skipped: Skipped[] } {
  const wanted: Wanted[] = [];
  const skipped: Skipped[] = [];
  for (const itemId of itemIds) {
    const line = lines[itemId];
    if (line === undefined || line.isBought) skipped.push({ itemId, reason: 'not-found' });
    else if (line.pick === null || line.pick.retailer !== shop.retailer) {
      skipped.push({ itemId, reason: 'no-match' });
    } else if (shop.isWeighedUnit(line.pick.unitOfMeasure)) {
      skipped.push({ itemId, reason: 'weighed-item' });
    } else wanted.push({ itemId, pick: line.pick });
  }
  return { wanted, skipped };
}
