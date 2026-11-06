import { logger } from 'firebase-functions/v2';

import type { GroceryLineReader } from '../cart_push/grocery_lines';
import type { Added, PushResult, SkipReason, Skipped, Wanted } from '../cart_push/push_outcome';
import { sortPushedItems } from '../cart_push/sort_pushed_items';
import { asWoolworths } from './as_woolworths';
import type {
  WoolworthsCart,
  WoolworthsCartLine,
  WoolworthsProduct,
  WoolworthsShop,
} from './woolworths_api';
import { refuseWoolworths } from './woolworths_errors';
import { planWoolworthsPush, quantitiesOf } from './woolworths_push_plan';
import { withWoolworthsSession, type WoolworthsSessionDeps } from './woolworths_session';

export const WOOLWORTHS_RETAILER = 'woolworths';
export const WOOLWORTHS_WEIGHED_UNIT = 'KG';
export const LOOKUPS_AT_ONCE = 4;

export interface WoolworthsCartPushDeps extends WoolworthsSessionDeps {
  readonly shop: WoolworthsShop;
  readonly groceries: GroceryLineReader;
}

export interface WoolworthsPushCall {
  readonly uid: string;
  readonly householdId: string;
  readonly itemIds: readonly string[];
  readonly quantities: Readonly<Record<string, number>>;
}

export async function pushToWoolworthsCart(
  deps: WoolworthsCartPushDeps,
  call: WoolworthsPushCall,
): Promise<PushResult> {
  const lines = await deps.groceries.read(call.householdId, call.itemIds);
  const sorted = sortPushedItems(call.itemIds, lines, {
    retailer: WOOLWORTHS_RETAILER,
    isWeighedUnit: (unit) => unit === WOOLWORTHS_WEIGHED_UNIT,
  });
  const packsOf = (itemId: string): number => call.quantities[itemId] ?? 1;
  return asWoolworths(
    () =>
      withWoolworthsSession(deps, call.uid, async (idToken) => {
        const cart = await deps.shop.readCart(idToken);
        if (cart.storeId === null) throw refuseWoolworths('woolworths-no-delivery-address');
        const products = await productsOf(deps.shop, idToken, sorted.wanted);
        const plan = planWoolworthsPush(sorted.wanted, packsOf, products, cart);
        if (plan.adds.length > 0) await deps.shop.addItems(idToken, plan.adds);
        const after = plan.adds.length > 0 ? await deps.shop.readCart(idToken) : cart;
        const { added, shortSkipped } = withShortfalls(
          plan.added,
          shortfalls(plan.adds, cart, after),
        );
        const skipped = [...sorted.skipped, ...plan.skipped, ...shortSkipped];
        logger.info('woolworths cart filled', {
          uid: call.uid,
          householdId: call.householdId,
          asked: call.itemIds.length,
          added: added.length,
          addedLines: plan.adds.length,
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

async function productsOf(
  shop: WoolworthsShop,
  idToken: string,
  wanted: readonly Wanted[],
): Promise<Record<string, WoolworthsProduct | null>> {
  const skus = [...new Set(wanted.map(({ pick }) => pick.productId))];
  const found: Record<string, WoolworthsProduct | null> = {};
  let next = 0;
  const worker = async (): Promise<void> => {
    while (next < skus.length) {
      const sku = skus[next] ?? '';
      next += 1;
      found[sku] = await shop.findProduct(idToken, sku);
    }
  };
  await Promise.all(Array.from({ length: Math.min(LOOKUPS_AT_ONCE, skus.length) }, worker));
  return found;
}

function shortfalls(
  adds: readonly WoolworthsCartLine[],
  before: WoolworthsCart,
  after: WoolworthsCart,
): Record<string, SkipReason> {
  const was = quantitiesOf(before);
  const now = quantitiesOf(after);
  const short: Record<string, SkipReason> = {};
  for (const { sku, quantity } of adds) {
    const gained = (now[sku] ?? 0) - (was[sku] ?? 0);
    if (gained <= 0) short[sku] = 'out-of-stock';
    else if (gained < quantity) short[sku] = 'low-stock';
  }
  return short;
}

function withShortfalls(
  planned: readonly Added[],
  short: Readonly<Record<string, SkipReason>>,
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
