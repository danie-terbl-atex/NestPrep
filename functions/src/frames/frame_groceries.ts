import { z } from 'zod';

import { normalisedName } from '../home_care/restock_decision';
import type { RankedMatch } from '../checkers/match_decisions';
import { type MemberRecord, type StoredHousehold, recipientsOf } from '../notifications/recipients';
import { firstName } from './frame_day';
import { refuseFrame } from './frame_errors';
import { FRAME_BEST_MATCH_FIT, FRAME_PRODUCT_LIMIT, type FrameGroceryShop } from './frame_policy';
import type { AddFrameGroceryItemInput, FrameProductPick } from './frame_schemas';
import { type FrameShopProduct, productImageUrl } from './frame_shop_catalogue';
import { membersNamed } from './frame_ticks';

/**
 * The rules of groceries added at the wall (photo-frames ADR-0012), pure so
 * they are tested where they live (`BE-14`).
 */

export const GROCERY_ITEMS = 'groceryItems';

/** A grocery item as the frame reads it; one that does not parse is left off. */
export const frameStoredGroceryItem = z.object({
  name: z.string().min(1),
  quantity: z.string().nullable().optional().catch(null),
  boughtBy: z.string().nullable().optional(),
  productMatch: z
    .object({
      retailer: z.string(),
      name: z.string().min(1),
      brand: z.string().nullable().optional().catch(null),
      imageId: z.string().nullable().optional().catch(null),
    })
    .nullable()
    .optional()
    .catch(null),
});
export type FrameStoredGroceryItem = z.infer<typeof frameStoredGroceryItem>;

export function isUnbought(item: FrameStoredGroceryItem): boolean {
  return item.boughtBy === null || item.boughtBy === undefined;
}

/**
 * The members who may add to the list, as the rules decide it: someone signs
 * in as the profile, and it holds `groceries` at `edit`.
 */
export function groceriesEditors(
  household: StoredHousehold,
  members: readonly MemberRecord[],
): string[] {
  return recipientsOf(household, members)
    .filter((recipient) => recipient.levels.groceries === 'edit')
    .map((recipient) => recipient.memberId);
}

/** The one groceries editor whose first name is [by]. */
export function groceryAdderNamed(
  editors: readonly string[],
  names: Readonly<Record<string, string>>,
  by: string,
): string {
  const [adder, ...others] = membersNamed(editors, names, by);
  if (adder === undefined) throw refuseFrame('notAllowedToAddGroceries');
  if (others.length > 0) throw refuseFrame('whoNeeded');
  return adder;
}

/** One id per frame and request, so a retry finds the item its first try wrote. */
export function frameGroceryId(frameId: string, requestId: string): string {
  return `frame-${frameId}-${requestId}`;
}

/** The pick as `groceriesIsProductMatch` reads it, less `pickedAt`, which is the server's clock. */
export function frameProductMatch(
  pick: FrameProductPick,
  pickedBy: string,
): Record<string, unknown> {
  return {
    retailer: pick.retailer,
    productId: pick.productId,
    articleCode: pick.articleCode,
    unitOfMeasure: pick.unitOfMeasure,
    name: pick.name,
    brand: pick.brand,
    priceCents: pick.priceCents,
    currency: 'ZAR',
    imageId: pick.imageId,
    pickedBy,
  };
}

/**
 * Exactly the typed item the app writes, less `addedAt` (and a pick's
 * `pickedAt`), which are the server's clock.
 */
export function frameGroceryItemDocument(
  input: AddFrameGroceryItemInput,
  addedBy: string,
): Record<string, unknown> {
  return {
    name: input.name,
    quantity: input.quantity,
    addedBy,
    boughtAt: null,
    boughtBy: null,
    sourceKey: null,
    sourceWeek: null,
    sourceNote: null,
  };
}

/** The unbought item answering to [name] — by what was typed, or the key it was planned under. */
export function sameItemOnList(
  name: string,
  unbought: readonly { readonly id: string; readonly name: string; readonly sourceKey?: unknown }[],
): string | null {
  const key = normalisedName(name);
  const match = unbought.find(
    (item) => normalisedName(item.name) === key || item.sourceKey === key,
  );
  return match?.id ?? null;
}

export interface FrameGroceryRow {
  readonly id: string;
  readonly name: string;
  readonly quantity?: string;
  readonly product?: { readonly name: string; readonly brand?: string; readonly imageUrl?: string };
}

export interface FrameGroceriesDay {
  readonly shop: FrameGroceryShop;
  readonly by: string[];
  readonly toBuy: FrameGroceryRow[];
}

export interface FrameGroceriesSources {
  readonly shop: FrameGroceryShop;
  readonly editors: readonly string[];
  /** Newest first, as read. */
  readonly items: readonly (FrameStoredGroceryItem & { readonly id: string })[];
}

function groceryRow(item: FrameStoredGroceryItem & { readonly id: string }): FrameGroceryRow {
  const quantity = item.quantity?.trim() ?? '';
  const match = item.productMatch ?? null;
  const imageUrl = match === null ? null : productImageUrl(match.retailer, match.imageId ?? null);
  const brand = match?.brand?.trim() ?? '';
  return {
    id: item.id,
    name: item.name,
    ...(quantity === '' ? {} : { quantity }),
    ...(match === null
      ? {}
      : {
          product: {
            name: match.name,
            ...(brand === '' ? {} : { brand }),
            ...(imageUrl === null ? {} : { imageUrl }),
          },
        }),
  };
}

/** What the wall shows of the list: who may add, and what is still to buy. */
export function groceriesPanel(
  sources: FrameGroceriesSources,
  names: Readonly<Record<string, string>>,
): FrameGroceriesDay {
  const by = sources.editors
    .map((id) => firstName(names[id] ?? ''))
    .filter((name) => name !== '')
    .sort((a, b) => a.localeCompare(b));
  return {
    shop: sources.shop,
    by,
    toBuy: sources.items.filter(isUnbought).map(groceryRow),
  };
}

/** A product as a frame search answers with it: what a pick needs, a picture, and Jev's verdict. */
export interface FrameProduct {
  readonly retailer: FrameGroceryShop;
  readonly productId: string;
  readonly articleCode: string;
  readonly unitOfMeasure: string;
  readonly name: string;
  readonly brand: string | null;
  readonly priceCents: number;
  readonly imageId: string | null;
  readonly imageUrl: string | null;
  readonly bestMatch: boolean;
}

/** What may be picked from a search, each product once: never one sold by weight, which no cart takes by the pack. */
export function searchableProducts(
  found: readonly FrameShopProduct[],
  limit: number,
): FrameShopProduct[] {
  const seen = new Set<string>();
  return found
    .filter((product) => {
      if (product.isSoldByWeight || seen.has(product.productId)) return false;
      seen.add(product.productId);
      return true;
    })
    .slice(0, limit);
}

/**
 * The answer, best first when Jev ranked them and in the shop's order when
 * it did not; the first is the best match only when Jev is sure of it.
 */
export function frameProductsInOrder(
  products: readonly FrameShopProduct[],
  ranking: readonly RankedMatch[] | null,
): FrameProduct[] {
  const ordered =
    ranking === null
      ? products.map((product) => ({ product, fit: 0 }))
      : ranking.flatMap(({ productId, fit }) => {
          const product = products.find((candidate) => candidate.productId === productId);
          return product === undefined ? [] : [{ product, fit }];
        });
  return ordered.slice(0, FRAME_PRODUCT_LIMIT).map(({ product, fit }, index) => ({
    retailer: product.retailer,
    productId: product.productId,
    articleCode: product.articleCode,
    unitOfMeasure: product.unitOfMeasure,
    name: product.name,
    brand: product.brand,
    priceCents: product.priceCents,
    imageId: product.imageId,
    imageUrl: productImageUrl(product.retailer, product.imageId),
    bestMatch: ranking !== null && index === 0 && fit >= FRAME_BEST_MATCH_FIT,
  }));
}
