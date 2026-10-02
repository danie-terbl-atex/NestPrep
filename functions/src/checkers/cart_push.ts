import { logger } from 'firebase-functions/v2';

import {
  CheckersSessionExpired,
  CheckersUnavailable,
  type CatalogProduct,
  type CheckersShop,
  type ShopContext,
} from './checkers_api';
import { refuseCheckers } from './errors';
import type { GroceryLineReader } from './grocery_lines';
import type { CheckersLinkStore } from './link_store';
import { liveSession } from './link_status';
import {
  itemCountOf,
  planLines,
  sortItems,
  type Added,
  type Skipped,
  type Wanted,
} from './push_plan';
import { openSession } from './sealed_values';

/** Products not found by id that are looked for again by article code, at most. */
export const MAX_ARTICLE_LOOKUPS = 5;

export interface CartPushDeps {
  readonly links: CheckersLinkStore;
  readonly shop: CheckersShop;
  readonly groceries: GroceryLineReader;
  readonly key: Buffer;
  readonly now: Date;
}

/** What `checkersPushToCart` answers (the Checkers build contract). */
export interface PushResult {
  readonly added: readonly Added[];
  readonly skipped: readonly Skipped[];
  readonly cartItemCount: number;
  readonly cartTotalCents: number;
}

/**
 * The matched items of a grocery list into the member's own Sixty60 cart —
 * cart only; never a slot, a checkout or a payment (the Checkers build
 * contract). The server reads the items itself and re-reads every product at
 * the member's stores; the caller's membership is checked before this runs.
 */
export async function pushToCheckersCart(
  deps: CartPushDeps,
  call: { uid: string; householdId: string; itemIds: readonly string[] },
): Promise<PushResult> {
  const context = await shopContextFor(deps, call.uid);
  const lines = await deps.groceries.read(call.householdId, call.itemIds);
  const sorted = sortItems(call.itemIds, lines);
  try {
    const products = await productsFor(deps.shop, context, sorted.wanted);
    const cart = await deps.shop.readCart(context);
    const plan = planLines(sorted.wanted, products, cart);
    const after =
      plan.lines.length > 0 ? await deps.shop.addLines(context, cart, plan.lines) : cart;
    const skipped = [...sorted.skipped, ...plan.skipped];
    logger.info('checkers cart filled', {
      uid: call.uid,
      householdId: call.householdId,
      asked: call.itemIds.length,
      added: plan.added.length,
      newLines: plan.lines.length,
      skipped: skipped.length,
    });
    return {
      added: plan.added,
      skipped,
      cartItemCount: itemCountOf(after),
      cartTotalCents: after.totalCents,
    };
  } catch (error) {
    if (error instanceof CheckersSessionExpired) throw refuseCheckers('checkers-link-expired');
    if (error instanceof CheckersUnavailable) {
      logger.warn('checkers cart not filled', { uid: call.uid, reason: error.reason });
      throw refuseCheckers('checkers-down');
    }
    throw error;
  }
}

/** The member's live session and stores, or the refusal that sends them to link again. */
async function shopContextFor(deps: CartPushDeps, uid: string): Promise<ShopContext> {
  const link = await deps.links.read(uid);
  const live = liveSession(link, deps.now);
  if (link === null || live === null) throw refuseCheckers('checkers-link-expired');
  const session = await openSession(deps.key, uid, live.sealed);
  if (session === null) {
    logger.warn('checkers session does not open', { uid });
    throw refuseCheckers('checkers-link-expired');
  }
  if (live.storeContexts.length === 0) throw refuseCheckers('no-checkers-store');
  return { session, storeContexts: live.storeContexts, deviceId: link.deviceId };
}

/**
 * Every picked product as the member's stores sell it today, keyed by the id
 * that was picked: by id first, then — for a few that were not found — by
 * article code, in case Checkers re-issued the id.
 */
async function productsFor(
  shop: CheckersShop,
  context: ShopContext,
  wanted: readonly Wanted[],
): Promise<Record<string, CatalogProduct>> {
  const picks = [...new Map(wanted.map(({ pick }) => [pick.productId, pick])).values()];
  if (picks.length === 0) return {};
  const found = await shop.findProducts(
    context,
    picks.map((pick) => pick.productId),
  );
  const byPick: Record<string, CatalogProduct> = Object.fromEntries(
    found.map((product) => [product.productId, product]),
  );
  const missing = picks.filter((pick) => byPick[pick.productId] === undefined);
  for (const pick of missing.slice(0, MAX_ARTICLE_LOOKUPS)) {
    const product = await shop.findByArticleCode(context, pick.articleCode);
    if (product !== null) byPick[pick.productId] = product;
  }
  return byPick;
}
