import { normalisedName } from '../home_care/restock_decision';
import {
  isLunchSlot,
  type LunchPlanFacts,
  type LunchSlot,
  type StoredPrice,
} from './week_documents';

/**
 * What the household's week of lunches costs at the till, for every child
 * together (lunch-box ADR-0012 §4): each thing's boxes across the household —
 * what is packed already and what the plan adds — in whole packs, at the
 * pack's price. The app's `LunchWeekCost` does the same sum over the board and
 * is what a parent sees on the budget screen; this one is what the week is
 * assembled within, so the two must agree.
 */

/** The app's `LunchItem.nameLimit`: a shop product's name is cut to it as it becomes a library item. */
export const LUNCH_ITEM_NAME_LIMIT = 60;

/** One library item already packed in the week, for any child. */
export interface InWeekItem {
  readonly itemId: string;
  readonly slot: LunchSlot;
  /** The packed name as a library key — how a shop product becomes this item again. */
  readonly nameKey: string;
  readonly boxes: number;
  /** Null when the household has not priced it: it is left out of the sum, as the budget screen does. */
  readonly price: StoredPrice | null;
}

/** One compartment the plan adds — or, for a dish, one of its ingredient products. */
export interface NewBox {
  readonly productId: string;
  readonly slot: LunchSlot;
  readonly name: string;
  /**
   * The dish this ingredient product is bought for (lunch-box ADR-0021 §5):
   * never an item of the week by name, and priced per dish — as the dish's
   * library item will be — so the plan and the meter read the same total.
   */
  readonly forDish?: string;
}

export interface ProductPack {
  readonly boxesPerPack: number;
  readonly priceCents: number;
}

/** Every item packed in the week starting [monday], across every child. */
export function inWeekItems(
  plans: readonly LunchPlanFacts[],
  monday: string,
  prices: Readonly<Record<string, StoredPrice>>,
): InWeekItem[] {
  const items: Record<string, { slot: LunchSlot; nameKey: string; boxes: number }> = {};
  for (const plan of plans) {
    if (plan.weekStart !== monday) continue;
    for (const [key, pick] of Object.entries(plan.slots)) {
      const slot = key.slice(key.indexOf('_') + 1);
      if (!isLunchSlot(slot)) continue;
      const known = items[pick.itemId];
      if (known === undefined) {
        items[pick.itemId] = { slot, nameKey: normalisedName(pick.name), boxes: 1 };
      } else {
        known.boxes += 1;
      }
    }
  }
  return Object.entries(items).map(([itemId, item]) => ({
    itemId,
    ...item,
    price: prices[itemId] ?? null,
  }));
}

/** The library key a shop product's name becomes (the app's `cutText` then `normalisedName`). */
export function itemNameKey(productName: string): string {
  return normalisedName(productName.trim().slice(0, LUNCH_ITEM_NAME_LIMIT));
}

/**
 * The whole week in cents: what is packed already plus [boxes], each thing's
 * boxes rounded up to whole packs once. A product whose name and slot are an
 * item already in the week *is* that item — *Use it* reuses it and writes the
 * shelf price over its old one (ADR-0012 §3) — so their boxes share packs.
 */
export function weekBasketCents(
  already: readonly InWeekItem[],
  boxes: readonly NewBox[],
  packOf: (productId: string) => ProductPack,
): number {
  const lines: Record<string, { boxes: number; portions: number; cents: number | null }> = {};
  for (const item of already) {
    lines[`item:${item.itemId}`] = {
      boxes: item.boxes,
      portions: item.price?.portions ?? 1,
      cents: item.price?.cents ?? null,
    };
  }
  for (const box of boxes) {
    const key = lineKeyOf(box, already);
    const pack = packOf(box.productId);
    lines[key] = {
      boxes: (lines[key]?.boxes ?? 0) + 1,
      portions: pack.boxesPerPack,
      cents: pack.priceCents,
    };
  }
  let total = 0;
  for (const line of Object.values(lines)) {
    if (line.cents === null || line.boxes === 0) continue;
    total += Math.ceil(line.boxes / Math.max(1, line.portions)) * line.cents;
  }
  return total;
}

function lineKeyOf(box: NewBox, already: readonly InWeekItem[]): string {
  if (box.forDish !== undefined) return `dish:${box.forDish}|${box.productId}`;
  const nameKey = itemNameKey(box.name);
  const same = already.find((item) => item.slot === box.slot && item.nameKey === nameKey);
  return same === undefined ? `product:${box.productId}|${box.slot}` : `item:${same.itemId}`;
}
