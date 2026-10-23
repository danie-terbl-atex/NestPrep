import type { PickedProduct } from './grocery_lines';

/**
 * What a push into a member's own shop cart answers, the same for every shop
 * (the Checkers build contract, add-to-pnp ADR-0004), so the app shows one
 * result for both. The last four are Pick n Pay's alone: a delivery cart there
 * holds a capped number of items (`cart-full`), and PnP may take fewer than
 * asked when stock is low (`low-stock`) or past a product's order limit
 * (`max-quantity`), or refuse one line outright (`shop-refused`) — each of
 * those the member is told about, item by item (add-to-pnp ADR-0004).
 */
export type SkipReason =
  | 'no-match'
  | 'out-of-stock'
  | 'not-found'
  | 'weighed-item'
  | 'cart-full'
  | 'low-stock'
  | 'max-quantity'
  | 'shop-refused';

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

/** A grocery item worth asking the shop about, with the product the member picked. */
export interface Wanted {
  readonly itemId: string;
  readonly pick: PickedProduct;
}

export interface PushResult {
  readonly added: readonly Added[];
  readonly skipped: readonly Skipped[];
  readonly cartItemCount: number;
  readonly cartTotalCents: number;
}
