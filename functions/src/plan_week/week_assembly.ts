import { SCHOOL_DAYS } from './iso_week';
import type { WeekBrief, WeekBriefChild, WeekBriefProduct } from './week_brief';
import type { WeekDecisions } from './week_decisions';
import { LUNCH_SLOTS, slotKey, type LunchSlot } from './week_documents';
import { lineCents, packsPlaced, weekCostOf, weekPricing, type WeekPricing } from './week_pricing';

export const MIN_FIT = 0.4;
export const MAX_DAYS_PER_PRODUCT = 3;
export { MAX_BOXES_PER_PACK } from './week_pricing';
const AISLE_LEAN = 0.05;
const REPEAT_COST = 0.15;
const PRICE_WEIGHT = 0.15;
const PRICE_WEIGHT_FAVOURED = 0.4;
const MAX_BUDGET_SWAPS = 60;

export interface ProposedLunch {
  readonly childId: string;
  readonly day: number;
  readonly slot: LunchSlot;
  readonly ideaId: string;
  readonly productId: string;
}

export interface ProposedPack {
  readonly productId: string;
  readonly boxesPerPack: number;
}

/** A dish placed in the week and the store products it is bought as (lunch-box ADR-0021). */
export interface ProposedDish {
  readonly ideaId: string;
  readonly parts: readonly { readonly ingredient: string; readonly productId: string }[];
}

export interface ProposedWeek {
  readonly lunches: readonly ProposedLunch[];
  readonly packs: readonly ProposedPack[];
  readonly dishes: readonly ProposedDish[];
  /** The household's whole week, packed and proposed, in whole packs (ADR-0012 §4). */
  readonly weekCents: number;
}

interface Placed {
  readonly child: WeekBriefChild;
  readonly day: number;
  product: WeekBriefProduct;
}

/**
 * The week from Jev's scores (foundation ADR-0021): each open compartment,
 * day by day, gets the product that suits most of the children still waiting —
 * so boxes are packed once — no product more than three days for a child
 * while another fits, then the dearest lines swapped for cheaper fits while
 * the household's whole week — what is packed already and what is placed
 * here, in whole packs together — is over budget (lunch-box ADR-0012 §4).
 */
export function assembleWeek(brief: WeekBrief, decisions: WeekDecisions): ProposedWeek {
  const usable = brief.products.filter((product) => (decisions.fit[product.ref] ?? 0) >= MIN_FIT);
  const pricing = weekPricing(decisions, brief.alreadyInWeek, brief.products);
  const { perBox } = pricing;
  const priceWeight = brief.preferences.includes('favourPrice')
    ? PRICE_WEIGHT_FAVOURED
    : PRICE_WEIGHT;
  const dearest = new Map<LunchSlot, number>(
    LUNCH_SLOTS.map((slot) => [
      slot,
      Math.max(1, ...usable.filter((p) => p.slot === slot).map(perBox)),
    ]),
  );
  const worth = (product: WeekBriefProduct): number =>
    (decisions.fit[product.ref] ?? 0) +
    (product.fromAisle ? AISLE_LEAN : 0) -
    (priceWeight * perBox(product)) / (dearest.get(product.slot) ?? 1);

  const uses: Record<string, number> = {};
  const usesOf = (child: WeekBriefChild, product: WeekBriefProduct): number =>
    uses[`${child.ref}|${product.product.productId}`] ?? 0;
  const placed: Placed[] = [];

  // A product past its days is used only when nothing else fits: a repeat beats an empty box.
  const bestFor = (
    waiting: readonly WeekBriefChild[],
    slot: LunchSlot,
    maxDays: number,
  ): { product: WeekBriefProduct; takers: WeekBriefChild[] } | null => {
    let best: { product: WeekBriefProduct; takers: WeekBriefChild[]; value: number } | null = null;
    for (const product of usable) {
      if (product.slot !== slot) continue;
      const takers = waiting.filter(
        (child) => product.childRefs.includes(child.ref) && usesOf(child, product) < maxDays,
      );
      if (takers.length === 0) continue;
      const value = takers.reduce(
        (sum, child) => sum + worth(product) - REPEAT_COST * usesOf(child, product),
        0,
      );
      if (
        best === null ||
        value > best.value ||
        (value === best.value && perBox(product) < perBox(best.product))
      ) {
        best = { product, takers, value };
      }
    }
    return best;
  };

  for (const day of SCHOOL_DAYS) {
    for (const slot of LUNCH_SLOTS) {
      let waiting = brief.children.filter((child) => child.open.includes(slotKey(day, slot)));
      while (waiting.length > 0) {
        const best =
          bestFor(waiting, slot, MAX_DAYS_PER_PRODUCT) ?? bestFor(waiting, slot, Infinity);
        if (best === null) break;
        for (const child of best.takers) {
          const key = `${child.ref}|${best.product.product.productId}`;
          uses[key] = (uses[key] ?? 0) + 1;
          placed.push({ child, day, product: best.product });
        }
        const taken = new Set(best.takers);
        waiting = waiting.filter((child) => !taken.has(child));
      }
    }
  }

  if (brief.budgetCents !== null) {
    keepWithin(brief.budgetCents, placed, usable, pricing, decisions);
  }

  const lunches = placed.map(({ child, day, product }) => ({
    childId: child.memberId,
    day,
    slot: product.slot,
    ideaId: product.ideaId,
    productId: product.product.productId,
  }));
  return {
    lunches,
    packs: packsPlaced(placed, pricing),
    dishes: dishesOf(placed),
    weekCents: weekCostOf(placed, pricing),
  };
}

function dishesOf(placed: readonly Placed[]): ProposedDish[] {
  const dishes: Record<string, ProposedDish> = {};
  for (const { product } of placed) {
    if (product.parts === undefined) continue;
    dishes[product.ideaId] ??= {
      ideaId: product.ideaId,
      parts: product.parts.map((part) => ({
        ingredient: part.ingredient,
        productId: part.product.productId,
      })),
    };
  }
  return Object.values(dishes);
}

/**
 * Swaps the dearest lines for cheaper fits while the household's whole week —
 * what is packed already and what is placed here — is over [budgetCents].
 */
function keepWithin(
  budgetCents: number,
  placed: Placed[],
  usable: readonly WeekBriefProduct[],
  pricing: WeekPricing,
  decisions: WeekDecisions,
): void {
  const { perBox } = pricing;
  const fitOf = (product: WeekBriefProduct): number => decisions.fit[product.ref] ?? 0;
  for (let swap = 0; swap < MAX_BUDGET_SWAPS; swap += 1) {
    const cost = weekCostOf(placed, pricing);
    if (cost <= budgetCents) return;
    const lines = [...new Set(placed.map((place) => place.product))].sort(
      (a, b) => lineCents(placed, b, pricing) - lineCents(placed, a, pricing),
    );
    let swapped = false;
    for (const line of lines) {
      const at = placed.filter((place) => place.product === line);
      const cheaper = usable
        .filter(
          (product) =>
            product.slot === line.slot &&
            product.product.productId !== line.product.productId &&
            perBox(product) < perBox(line) &&
            at.every((place) => product.childRefs.includes(place.child.ref)),
        )
        .sort((a, b) => fitOf(b) - fitOf(a) || perBox(a) - perBox(b));
      for (const product of cheaper) {
        for (const place of at) place.product = product;
        if (weekCostOf(placed, pricing) < cost) {
          swapped = true;
          break;
        }
        for (const place of at) place.product = line;
      }
      if (swapped) break;
    }
    if (!swapped) return;
  }
}
