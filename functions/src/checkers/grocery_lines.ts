import type { Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { groceryItems } from '../home_care/home_care_refs';

/** The part of a member's pick a push needs; the rest is display, re-read from Checkers. */
export interface PickedProduct {
  readonly retailer: string;
  readonly productId: string;
  readonly articleCode: string;
  readonly unitOfMeasure: string;
}

export interface GroceryLine {
  readonly itemId: string;
  readonly isBought: boolean;
  /** Null when nobody picked a product, or the pick does not read. */
  readonly pick: PickedProduct | null;
}

const lineShape = z.object({
  boughtBy: z.string().nullish(),
  productMatch: z.unknown().optional(),
});

const pickShape = z.object({
  retailer: z.string(),
  productId: z.string(),
  articleCode: z.string(),
  unitOfMeasure: z.string(),
});

/** A grocery item as a push reads it, from the stored document (ENG-09). */
export function groceryLineOf(itemId: string, data: unknown): GroceryLine {
  const line = lineShape.safeParse(data);
  const pick = pickShape.safeParse(line.success ? line.data.productMatch : null);
  return {
    itemId,
    isBought: line.success && typeof line.data.boughtBy === 'string',
    pick: pick.success ? pick.data : null,
  };
}

/**
 * The grocery items a push names, read by the server itself — the client's
 * idea of what was picked is never trusted (BE-03). An id with no document is
 * absent from the answer.
 */
export interface GroceryLineReader {
  read(householdId: string, itemIds: readonly string[]): Promise<Record<string, GroceryLine>>;
}

export class FirestoreGroceryLines implements GroceryLineReader {
  constructor(private readonly store: Firestore) {}

  async read(
    householdId: string,
    itemIds: readonly string[],
  ): Promise<Record<string, GroceryLine>> {
    const list = groceryItems(this.store, householdId);
    const snapshots = await this.store.getAll(...itemIds.map((id) => list.doc(id)));
    return Object.fromEntries(
      snapshots
        .filter((snapshot) => snapshot.exists)
        .map((snapshot) => [snapshot.id, groceryLineOf(snapshot.id, snapshot.data())]),
    );
  }
}
