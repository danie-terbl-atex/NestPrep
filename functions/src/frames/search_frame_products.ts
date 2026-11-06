import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { DECISION_SECRETS } from '../ai/ai_config';
import { decisionRuntime } from '../ai/ai_runtime';
import { askDecisions } from '../ai/run_decision_call';
import { matchRequest, rankedFrom, type RankedMatch } from '../checkers/match_decisions';
import { MAX_RANKED_PRODUCTS } from '../checkers/schemas';
import { parseInput } from '../household/parse_input';
import { readFlag, type FeatureFlag } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { readLinkedFrame } from './frame_access';
import { refuseFrame } from './frame_errors';
import { type FrameProduct, frameProductsInOrder, searchableProducts } from './frame_groceries';
import {
  FRAME_DEVICE_OPTIONS,
  FRAME_SEARCH_PRODUCTS_PER_CREDENTIAL,
  type FrameGroceryShop,
} from './frame_policy';
import { searchFrameProductsInput } from './frame_schemas';
import {
  FrameShopUnavailable,
  type FrameShopProduct,
  frameCatalogueHere,
} from './frame_shop_catalogue';

export type SearchFrameProductsResult =
  { status: 'unlinked' } | { status: 'linked'; products: FrameProduct[] };

const UNLINKED: SearchFrameProductsResult = { status: 'unlinked' };

const SHOP_FLAGS: Record<FrameGroceryShop, FeatureFlag> = {
  checkers: 'addToCheckers',
  pickNPay: 'addToPnp',
  woolworths: 'addToWoolworths',
};

/**
 * A linked frame looks a grocery item up at the family's shop for it
 * (photo-frames ADR-0012): the frame's shop, near the frame's area — at
 * Woolworths, the store the phone found for it — ranked by
 * Jev as the phone's matches are. A ranking that fails keeps the shop's order.
 */
export const searchFrameProducts = onCall(
  { ...FRAME_DEVICE_OPTIONS, secrets: DECISION_SECRETS, timeoutSeconds: 60 },
  async (request): Promise<SearchFrameProductsResult> => {
    const input = parseInput(searchFrameProductsInput, request.data);
    const store = db();
    const linked = await readLinkedFrame(store, input.secret, FRAME_SEARCH_PRODUCTS_PER_CREDENTIAL);
    if (linked === null) return UNLINKED;
    const { groceries } = linked.frame;
    if (groceries === null) throw refuseFrame('groceriesOff');
    if (!(await readFlag(store, SHOP_FLAGS[groceries.shop]))) throw refuseFrame('shopUnavailable');

    let found: FrameShopProduct[];
    try {
      found = await frameCatalogueHere().search(groceries, input.query, MAX_RANKED_PRODUCTS);
    } catch (error) {
      if (!(error instanceof FrameShopUnavailable)) throw error;
      logger.warn('frame shop search failed', { shop: groceries.shop, reason: error.reason });
      throw refuseFrame('shopUnavailable');
    }
    const products = searchableProducts(found, MAX_RANKED_PRODUCTS);
    const ranking = await rankingOf(store, linked.home.id, groceries.shop, input.query, products);
    return { status: 'linked', products: frameProductsInOrder(products, ranking) };
  },
);

async function rankingOf(
  store: Firestore,
  householdId: string,
  retailer: FrameGroceryShop,
  item: string,
  products: readonly FrameShopProduct[],
): Promise<RankedMatch[] | null> {
  if (products.length === 0) return null;
  const input = {
    householdId,
    retailer,
    item,
    products: products.map((product) => ({
      productId: product.productId,
      name: product.name,
      brand: product.brand,
      priceCents: product.priceCents,
    })),
  };
  try {
    return rankedFrom(
      await askDecisions(await decisionRuntime(store), 'productMatch', matchRequest(input)),
      input,
    );
  } catch (error) {
    logger.info('frame product ranking skipped', {
      reason: error instanceof Error ? error.name : 'unknown',
    });
    return null;
  }
}
