import { logger } from 'firebase-functions/v2';

import type { GroceryLineReader } from '../cart_push/grocery_lines';
import type { Added, PushResult, Skipped, Wanted } from '../cart_push/push_outcome';
import { sortPushedItems } from '../cart_push/sort_pushed_items';
import { asPnp } from './as_pnp';
import type { CartWriteShortfall, PnpCart, PnpProduct, PnpShop } from './pnp_api';
import { refusePnp } from './pnp_errors';
import { planPnpPush, type CartRaise } from './pnp_push_plan';
import { withPnpSession, type PnpSessionDeps } from './pnp_session';

/** As stored in `productMatch.retailer` (groceries ADR-0007). */
export const PNP_RETAILER = 'pickNPay';

/** Weighed PnP codes end `_KGM`: their quantity is grams, which no push guesses. */
export const PNP_WEIGHED_UNIT = 'KGM';

export interface PnpCartPushDeps extends PnpSessionDeps {
  readonly shop: PnpShop;
  readonly groceries: GroceryLineReader;
}

export interface PnpPushCall {
  readonly uid: string;
  readonly householdId: string;
  readonly itemIds: readonly string[];
  readonly quantities: Readonly<Record<string, number>>;
}

/**
 * The matched items of a grocery list into the member's own PnP cart, as
 * many packs as asked (add-to-pnp ADR-0004) — cart only; never a slot, a
 * fulfilment option, a payment or an order. The server reads the items
 * itself, reads the member's cart for its store, and re-reads every product
 * there; the caller's membership is checked before this runs.
 */
export async function pushToPnpCart(deps: PnpCartPushDeps, call: PnpPushCall): Promise<PushResult> {
  const lines = await deps.groceries.read(call.householdId, call.itemIds);
  const sorted = sortPushedItems(call.itemIds, lines, {
    retailer: PNP_RETAILER,
    isWeighedUnit: (unit) => unit === PNP_WEIGHED_UNIT,
  });
  const packsOf = (itemId: string): number => call.quantities[itemId] ?? 1;
  return asPnp(
    () =>
      withPnpSession(deps, call.uid, async (accessToken) => {
        const cart = await deps.shop.readCart(accessToken);
        const storeCode = cart.storeCode;
        if (storeCode === null) throw refusePnp('pnp-no-delivery-address');
        const products = await productsAt(deps.shop, accessToken, storeCode, sorted.wanted);
        const plan = planPnpPush(sorted.wanted, packsOf, products, cart);
        const short = await raiseLines(deps.shop, accessToken, cart, plan.raises);
        const after = plan.raises.length > 0 ? await deps.shop.readCart(accessToken) : cart;
        const { added, shortSkipped } = withShortfalls(plan.added, short);
        const skipped = [...sorted.skipped, ...plan.skipped, ...shortSkipped];
        logger.info('pnp cart filled', {
          uid: call.uid,
          householdId: call.householdId,
          asked: call.itemIds.length,
          added: added.length,
          raisedLines: plan.raises.length,
          skipped: skipped.length,
        });
        return {
          added,
          skipped,
          cartItemCount: after.itemCount,
          cartTotalCents: after.totalCents,
        };
      }),
    'cart not filled',
  );
}

/** How many product lookups run at once: the push's whole budget is two minutes. */
export const LOOKUPS_AT_ONCE = 4;

/** Every picked product as the cart's own store sells it today, by the code that was picked. */
async function productsAt(
  shop: PnpShop,
  accessToken: string,
  storeCode: string,
  wanted: readonly Wanted[],
): Promise<Record<string, PnpProduct | null>> {
  const codes = [...new Set(wanted.map(({ pick }) => pick.productId))];
  const found: Record<string, PnpProduct | null> = {};
  let next = 0;
  const worker = async (): Promise<void> => {
    while (next < codes.length) {
      const code = codes[next] ?? '';
      next += 1;
      found[code] = await shop.findProduct(accessToken, storeCode, code);
    }
  };
  await Promise.all(Array.from({ length: Math.min(LOOKUPS_AT_ONCE, codes.length) }, worker));
  return found;
}

/**
 * One write at a time; each is absolute, so a push that stops part-way is
 * finished by the next. Answers what PnP did not do, by product code.
 */
async function raiseLines(
  shop: PnpShop,
  accessToken: string,
  cart: PnpCart,
  raises: readonly CartRaise[],
): Promise<Record<string, CartWriteShortfall>> {
  const short: Record<string, CartWriteShortfall> = {};
  for (const raise of raises) {
    const shortfall =
      raise.entryGuid === null
        ? await shop.addEntry(accessToken, cart.code, raise.productCode, raise.quantity)
        : await shop.setQuantity(accessToken, cart.code, raise.entryGuid, raise.quantity);
    if (shortfall !== null) short[raise.productCode] = shortfall;
  }
  return short;
}

/** The items whose product PnP fell short on leave the added list, each with PnP's reason. */
function withShortfalls(
  planned: readonly Added[],
  short: Readonly<Record<string, CartWriteShortfall>>,
): { added: Added[]; shortSkipped: Skipped[] } {
  const added: Added[] = [];
  const shortSkipped: Skipped[] = [];
  for (const line of planned) {
    const reason = short[line.productId];
    if (reason === undefined) added.push(line);
    else shortSkipped.push({ itemId: line.itemId, reason });
  }
  return { added, shortSkipped };
}
