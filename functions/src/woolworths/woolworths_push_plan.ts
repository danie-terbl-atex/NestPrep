import type { Added, Skipped, Wanted } from '../cart_push/push_outcome';
import type { WoolworthsCart, WoolworthsCartLine, WoolworthsProduct } from './woolworths_api';

export interface WoolworthsPushPlan {
  readonly adds: WoolworthsCartLine[];
  readonly added: Added[];
  readonly skipped: Skipped[];
}

export function quantitiesOf(cart: WoolworthsCart): Record<string, number> {
  const bySku: Record<string, number> = {};
  for (const line of cart.lines) bySku[line.sku] = (bySku[line.sku] ?? 0) + line.quantity;
  return bySku;
}

export function planWoolworthsPush(
  wanted: readonly Wanted[],
  packsOf: (itemId: string) => number,
  productsBySku: Readonly<Record<string, WoolworthsProduct | null>>,
  cart: WoolworthsCart,
): WoolworthsPushPlan {
  const inCart = quantitiesOf(cart);
  const asked: Record<string, number> = {};
  const added: Added[] = [];
  const skipped: Skipped[] = [];
  for (const { itemId, pick } of wanted) {
    const product = productsBySku[pick.productId] ?? null;
    if (product === null) {
      skipped.push({ itemId, reason: 'not-found' });
      continue;
    }
    if (product.isWeighed) {
      skipped.push({ itemId, reason: 'weighed-item' });
      continue;
    }
    asked[product.sku] = (asked[product.sku] ?? 0) + packsOf(itemId);
    added.push({
      itemId,
      productId: product.sku,
      name: product.name,
      priceCents: product.priceCents,
    });
  }
  const adds = Object.entries(asked)
    .map(([sku, quantity]) => ({ sku, quantity: Math.max(0, quantity - (inCart[sku] ?? 0)) }))
    .filter((line) => line.quantity > 0);
  return { adds, added, skipped };
}
