import { z } from 'zod';

/**
 * When a product belongs on the grocery list (home-care ADR-0005), decided
 * over the product before and after one write. Pure, so every crossing is
 * tested without an emulator.
 */
export const STOCK_LEVELS = ['full', 'half', 'low', 'out'] as const;
export type StockLevel = (typeof STOCK_LEVELS)[number];

const RUNNING_OUT: readonly StockLevel[] = ['low', 'out'];

const storedProduct = z.object({
  name: z.string().min(1),
  stock: z.enum(STOCK_LEVELS).optional(),
  stockChangedBy: z.string().min(1).nullable().optional(),
});

/** What the grocery line is made of: the product's name and who marked it. */
export interface Restock {
  readonly name: string;
  readonly markedBy: string;
}

/** A product written before the stock tracker has no level, which reads as full. */
function levelOf(data: unknown): StockLevel {
  const product = storedProduct.safeParse(data);
  return product.success ? (product.data.stock ?? 'full') : 'full';
}

/**
 * The line to add when this write moved the product *into* low or out — from
 * full, half, nothing, or not existing — and null otherwise. Low to out adds
 * nothing: it is already on its way to the list.
 */
export function restockFor(before: unknown, after: unknown): Restock | null {
  const product = storedProduct.safeParse(after);
  if (!product.success) return null;
  const now = product.data.stock ?? 'full';
  if (!RUNNING_OUT.includes(now) || RUNNING_OUT.includes(levelOf(before))) return null;
  const markedBy = product.data.stockChangedBy;
  if (markedBy === undefined || markedBy === null) return null;
  return { name: product.data.name, markedBy };
}

/** The grocery list's key for a name — groceries' `normalisedName`, in TypeScript. */
export function normalisedName(name: string): string {
  return name.trim().toLowerCase().replace(/\s+/g, ' ');
}

/** The derived id a product's line always has, so adding it twice is one line. */
export function groceryLineId(productId: string): string {
  return `homeCare-${productId}`;
}
