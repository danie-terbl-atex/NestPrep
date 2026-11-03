import { weekBasketCents, type InWeekItem, type NewBox } from './basket';
import type { WeekBriefProduct } from './week_brief';
import type { WeekDecisions } from './week_decisions';

export const MAX_BOXES_PER_PACK = 100;

/**
 * One pack the till charges for a week entry: a product is its own pack; a
 * dish is one pack line per ingredient product it is bought as (lunch-box
 * ADR-0021 §4).
 */
export interface PackLine {
  readonly productId: string;
  readonly name: string;
  readonly priceCents: number;
  readonly boxesPerPack: number;
  readonly isIngredient: boolean;
}

/** One entry placed in one child's compartment on one day. */
export interface PlacedEntry {
  readonly product: WeekBriefProduct;
}

/** How the week is priced: an entry's packs, a box's share, and what is packed already. */
export interface WeekPricing {
  readonly packsOf: (product: WeekBriefProduct) => readonly PackLine[];
  readonly perBox: (product: WeekBriefProduct) => number;
  readonly already: readonly InWeekItem[];
}

/**
 * How [products] are priced. A product can be reckoned under several ideas
 * (or as a dish's ingredient) with different pack sizes; it gets **one**: the
 * smallest, so the week never counts fewer packs than the till sells, and
 * the total and the packs the phone reads agree.
 */
export function weekPricing(
  decisions: WeekDecisions,
  already: readonly InWeekItem[],
  products: readonly WeekBriefProduct[],
): WeekPricing {
  const reckoned = (ref: string, packQuantity: number | null): number =>
    clampBoxes(packQuantity ?? decisions.boxes[ref] ?? 1);
  const smallest: Record<string, number> = {};
  for (const entry of products) {
    for (const { ref, product } of entry.parts ?? [entry]) {
      const boxes = reckoned(ref, product.packQuantity);
      smallest[product.productId] = Math.min(smallest[product.productId] ?? boxes, boxes);
    }
  }
  const boxes = (ref: string, product: WeekBriefProduct['product']): number =>
    smallest[product.productId] ?? reckoned(ref, product.packQuantity);
  const packsOf = (entry: WeekBriefProduct): PackLine[] =>
    entry.parts === undefined
      ? [
          {
            productId: entry.product.productId,
            name: entry.product.name,
            priceCents: entry.product.priceCents,
            boxesPerPack: boxes(entry.ref, entry.product),
            isIngredient: false,
          },
        ]
      : entry.parts.map((part) => ({
          productId: part.product.productId,
          name: part.product.name,
          priceCents: part.product.priceCents,
          boxesPerPack: boxes(part.ref, part.product),
          isIngredient: true,
        }));
  const perBox = (entry: WeekBriefProduct): number =>
    packsOf(entry).reduce((sum, pack) => sum + pack.priceCents / pack.boxesPerPack, 0);
  return { packsOf, perBox, already };
}

/**
 * The household's whole week in cents with [placed] added: what is packed
 * already plus every pack line of every placed entry, rounded up to whole
 * packs once. A dish's ingredients are priced per dish, as its library item
 * will be (lunch-box ADR-0021 §5).
 */
export function weekCostOf(placed: readonly PlacedEntry[], pricing: WeekPricing): number {
  const packs: Record<string, PackLine> = {};
  const boxes: NewBox[] = [];
  for (const { product } of placed) {
    for (const pack of pricing.packsOf(product)) {
      packs[pack.productId] = pack;
      boxes.push({
        productId: pack.productId,
        slot: product.slot,
        name: pack.name,
        ...(pack.isIngredient && { forDish: product.product.productId }),
      });
    }
  }
  return weekBasketCents(pricing.already, boxes, (productId) => {
    const pack = packs[productId];
    return pack === undefined
      ? { boxesPerPack: 1, priceCents: 0 }
      : { boxesPerPack: pack.boxesPerPack, priceCents: pack.priceCents };
  });
}

/** What one entry's boxes in [placed] cost on their own, in whole packs — to rank swaps. */
export function lineCents(
  placed: readonly PlacedEntry[],
  entry: WeekBriefProduct,
  pricing: WeekPricing,
): number {
  const boxes = placed.filter(
    (place) => place.product.product.productId === entry.product.productId,
  ).length;
  return pricing
    .packsOf(entry)
    .reduce((sum, pack) => sum + Math.ceil(boxes / pack.boxesPerPack) * pack.priceCents, 0);
}

/**
 * Every pack [entries] are bought as, once each, with the boxes it does —
 * every product kept, not only the placed ones, so a swap on the phone is
 * priced at its real pack (lunch-box ADR-0028 §7).
 */
export function everyPack(
  entries: readonly WeekBriefProduct[],
  pricing: WeekPricing,
): { productId: string; boxesPerPack: number }[] {
  const packs: Record<string, number> = {};
  for (const entry of entries) {
    for (const pack of pricing.packsOf(entry)) packs[pack.productId] ??= pack.boxesPerPack;
  }
  return Object.entries(packs).map(([productId, boxesPerPack]) => ({ productId, boxesPerPack }));
}

function clampBoxes(value: number): number {
  return Math.min(MAX_BOXES_PER_PACK, Math.max(1, Math.round(value)));
}
