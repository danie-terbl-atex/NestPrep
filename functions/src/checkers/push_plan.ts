import type { Added, Skipped, Wanted } from '../cart_push/push_outcome';
import { sortPushedItems } from '../cart_push/sort_pushed_items';
import type { GroceryLine } from '../cart_push/grocery_lines';
import type { Cart, CatalogProduct, NewCartLine } from './checkers_api';

/**
 * Which grocery items go into the member's Checkers cart, and as what (the
 * Checkers build contract) — decided without Checkers or Firestore, so every
 * rule here is a unit test.
 */
export type { Added, SkipReason, Skipped, Wanted } from '../cart_push/push_outcome';

/** Sold by the kilogram: its cart line needs a weight choice the app captures and we do not. */
export const WEIGHED_UNIT = 'KG';

/**
 * The items worth asking Checkers about. A weighed pick is `weighed-item`,
 * because a weighed line needs a weight range nobody has captured the shape of.
 */
export function sortItems(
  itemIds: readonly string[],
  lines: Readonly<Record<string, GroceryLine>>,
): { wanted: Wanted[]; skipped: Skipped[] } {
  return sortPushedItems(itemIds, lines, {
    retailer: 'checkers',
    isWeighedUnit: (unit) => unit === WEIGHED_UNIT,
  });
}

export interface CheckersPushPlan {
  readonly lines: NewCartLine[];
  readonly wantedInCart: Readonly<Record<string, number>>;
  readonly added: Added[];
  readonly skipped: Skipped[];
}

/**
 * The cart lines to write. Per product the wanted quantity is the sum of its
 * items' packs, and only what the cart is short of it is added — never
 * lowered, so a second push of the same list changes nothing and a member's
 * own extra packs stay (BE-06). A product already in the cart grows on its own
 * line; a product not in it is a new line. Every item of a product Checkers
 * sells is counted as added. The price is today's, at the member's store.
 */
export function planLines(
  wanted: readonly Wanted[],
  packsOf: (itemId: string) => number,
  productsByPick: Readonly<Record<string, CatalogProduct>>,
  cart: Cart,
): CheckersPushPlan {
  const asked: Record<string, { product: CatalogProduct; quantity: number }> = {};
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
    asked[productId] = { product, quantity: (asked[productId]?.quantity ?? 0) + packsOf(itemId) };
  }
  const inCart = quantitiesOf(cart);
  const lines: NewCartLine[] = [];
  const wantedInCart: Record<string, number> = {};
  for (const { product, quantity } of Object.values(asked)) {
    const short = quantity - (inCart[product.productId] ?? 0);
    if (short <= 0) continue;
    const existing = cart.lines.find((line) => line.productId === product.productId);
    lines.push({
      lineId: existing?.lineId ?? null,
      productId: product.productId,
      storeId: product.storeId,
      priceCents: product.priceCents,
      quantity: (existing?.quantity ?? 0) + short,
    });
    wantedInCart[product.productId] = quantity;
  }
  return { lines, wantedInCart, added, skipped };
}

export function withShortfalls(
  plan: CheckersPushPlan,
  before: Cart,
  after: Cart,
): { added: Added[]; skipped: Skipped[] } {
  const was = quantitiesOf(before);
  const now = quantitiesOf(after);
  const added: Added[] = [];
  const skipped: Skipped[] = [];
  for (const line of plan.added) {
    const wanted = plan.wantedInCart[line.productId];
    const has = now[line.productId] ?? 0;
    if (wanted === undefined || has >= wanted) added.push(line);
    else {
      const reason = has > (was[line.productId] ?? 0) ? 'low-stock' : 'out-of-stock';
      skipped.push({ itemId: line.itemId, reason });
    }
  }
  return { added, skipped };
}

function quantitiesOf(cart: Cart): Record<string, number> {
  const byProduct: Record<string, number> = {};
  for (const line of cart.lines) {
    byProduct[line.productId] = (byProduct[line.productId] ?? 0) + line.quantity;
  }
  return byProduct;
}

function skipReasonFor(product: CatalogProduct | undefined): Skipped['reason'] | null {
  if (product === undefined) return 'not-found';
  if (product.isSoldByWeight) return 'weighed-item';
  if (!product.isInStock) return 'out-of-stock';
  return null;
}

/** How many items the cart holds — a line of three is three. */
export function itemCountOf(cart: Cart): number {
  return cart.lines.reduce((total, line) => total + line.quantity, 0);
}
