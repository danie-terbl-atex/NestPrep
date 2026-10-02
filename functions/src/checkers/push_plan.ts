import type { Cart, CatalogProduct, NewCartLine } from './checkers_api';
import type { GroceryLine, PickedProduct } from './grocery_lines';

/**
 * Which grocery items go into the member's Checkers cart, and as what (the
 * Checkers build contract) — decided without Checkers or Firestore, so every
 * rule here is a unit test.
 */
export type SkipReason = 'no-match' | 'out-of-stock' | 'not-found' | 'weighed-item';

export interface Skipped {
  readonly itemId: string;
  readonly reason: SkipReason;
}

export interface Added {
  readonly itemId: string;
  readonly productId: string;
  readonly name: string;
  readonly priceCents: number;
}

export interface Wanted {
  readonly itemId: string;
  readonly pick: PickedProduct;
}

/** Sold by the kilogram: its cart line needs a weight choice the app captures and we do not. */
export const WEIGHED_UNIT = 'KG';

/**
 * The items worth asking Checkers about. An item that is gone or already
 * bought is `not-found` — it is no longer on the list to buy; one with no
 * Checkers pick is `no-match`; a weighed pick is `weighed-item`, because a
 * weighed line needs a weight range nobody has captured the shape of.
 */
export function sortItems(
  itemIds: readonly string[],
  lines: Readonly<Record<string, GroceryLine>>,
): { wanted: Wanted[]; skipped: Skipped[] } {
  const wanted: Wanted[] = [];
  const skipped: Skipped[] = [];
  for (const itemId of itemIds) {
    const line = lines[itemId];
    if (line === undefined || line.isBought) skipped.push({ itemId, reason: 'not-found' });
    else if (line.pick === null || line.pick.retailer !== 'checkers') {
      skipped.push({ itemId, reason: 'no-match' });
    } else if (line.pick.unitOfMeasure === WEIGHED_UNIT) {
      skipped.push({ itemId, reason: 'weighed-item' });
    } else wanted.push({ itemId, pick: line.pick });
  }
  return { wanted, skipped };
}

/**
 * The cart lines to add. Each item is one of its product; two items of one
 * product are one line of two. A product already in the cart is left exactly
 * as it is and counted as added — so pushing the same list twice never
 * doubles the cart (BE-06). The price is today's, at the member's store.
 */
export function planLines(
  wanted: readonly Wanted[],
  productsByPick: Readonly<Record<string, CatalogProduct>>,
  cart: Cart,
): { lines: NewCartLine[]; added: Added[]; skipped: Skipped[] } {
  const inCart = new Set(cart.lines.map((line) => line.productId));
  const quantities: Record<string, { product: CatalogProduct; quantity: number }> = {};
  const added: Added[] = [];
  const skipped: Skipped[] = [];
  for (const { itemId, pick } of wanted) {
    const product = productsByPick[pick.productId];
    const reason = skipReasonFor(product);
    if (product === undefined || reason !== null) {
      skipped.push({ itemId, reason: reason ?? 'not-found' });
      continue;
    }
    const { productId, name, priceCents } = product;
    added.push({ itemId, productId, name, priceCents });
    if (inCart.has(productId)) continue;
    const entry = quantities[productId] ?? { product, quantity: 0 };
    quantities[productId] = { product, quantity: entry.quantity + 1 };
  }
  const lines = Object.values(quantities).map(({ product, quantity }) => ({
    productId: product.productId,
    storeId: product.storeId,
    priceCents: product.priceCents,
    quantity,
  }));
  return { lines, added, skipped };
}

function skipReasonFor(product: CatalogProduct | undefined): SkipReason | null {
  if (product === undefined) return 'not-found';
  if (product.isSoldByWeight) return 'weighed-item';
  if (!product.isInStock) return 'out-of-stock';
  return null;
}

/** How many items the cart holds — a line of three is three. */
export function itemCountOf(cart: Cart): number {
  return cart.lines.reduce((total, line) => total + line.quantity, 0);
}
