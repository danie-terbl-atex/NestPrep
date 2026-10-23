import type { Added, Skipped, Wanted } from '../cart_push/push_outcome';
import type { PnpCart, PnpProduct } from './pnp_api';

/** A delivery cart's item cap when PnP does not say — the hub stores' 45. */
export const DEFAULT_CART_CAP = 45;

/** One line to raise: a new line when there is no entry, else an absolute quantity on it. */
export interface CartRaise {
  readonly productCode: string;
  readonly entryGuid: string | null;
  readonly quantity: number;
}

export interface PnpPushPlan {
  readonly raises: CartRaise[];
  readonly added: Added[];
  readonly skipped: Skipped[];
}

/**
 * Which picked items go into the member's PnP cart, and how many of each
 * (add-to-pnp ADR-0004) — decided without PnP or Firestore, so every rule is
 * a unit test.
 *
 * Per product the wanted quantity is the sum of its items' packs, and the
 * line is raised to at least that — never lowered, so a second push of the
 * same week changes nothing and a member's own extra packs stay (BE-06).
 * Items are taken in the order asked; one whose raise would pass the cart's
 * item cap is `cart-full`. A raise stops at the product's own order limit.
 */
export function planPnpPush(
  wanted: readonly Wanted[],
  packsOf: (itemId: string) => number,
  productsByCode: Readonly<Record<string, PnpProduct | null>>,
  cart: PnpCart,
): PnpPushPlan {
  const inCart: Record<string, { guid: string; quantity: number }> = Object.fromEntries(
    cart.entries.map((entry) => [
      entry.productCode,
      { guid: entry.guid, quantity: entry.quantity },
    ]),
  );
  const cap = cart.maxItems ?? DEFAULT_CART_CAP;
  const asked: Record<string, number> = {};
  const target: Record<string, number> = {};
  let itemCount = cart.itemCount;
  const added: Added[] = [];
  const skipped: Skipped[] = [];
  for (const { itemId, pick } of wanted) {
    const product = productsByCode[pick.productId] ?? null;
    const reason = skipReasonFor(product);
    if (product === null || reason !== null) {
      skipped.push({ itemId, reason: reason ?? 'not-found' });
      continue;
    }
    const already = inCart[product.code]?.quantity ?? 0;
    const planned = target[product.code] ?? already;
    const askedNow = (asked[product.code] ?? 0) + packsOf(itemId);
    // At least what is asked, never past the product's order limit, never lower.
    const limit = product.maxOrderQuantity ?? Number.POSITIVE_INFINITY;
    const next = Math.max(already, Math.min(askedNow, limit));
    const raise = next - planned;
    if (itemCount + raise > cap) {
      skipped.push({ itemId, reason: 'cart-full' });
      continue;
    }
    asked[product.code] = askedNow;
    target[product.code] = next;
    itemCount += raise;
    added.push({
      itemId,
      productId: product.code,
      name: product.name,
      priceCents: product.priceCents,
    });
  }
  const raises = Object.entries(target)
    .filter(([code, quantity]) => quantity > (inCart[code]?.quantity ?? 0))
    .map(([code, quantity]) => ({
      productCode: code,
      entryGuid: inCart[code]?.guid ?? null,
      quantity,
    }));
  return { raises, added, skipped };
}

function skipReasonFor(product: PnpProduct | null): Skipped['reason'] | null {
  if (product === null) return 'not-found';
  if (product.isWeighed) return 'weighed-item';
  if (!product.isInStock) return 'out-of-stock';
  return null;
}
