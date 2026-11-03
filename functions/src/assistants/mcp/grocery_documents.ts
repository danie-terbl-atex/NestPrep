import type { CollectionReference, Firestore } from 'firebase-admin/firestore';
import { z } from 'zod';

import { normalisedName } from '../../home_care/restock_decision';
import { HOUSEHOLDS } from '../../household/documents';
import type { AssistantMember } from '../assistant_access';
import { ASSISTANT_VIAS } from '../principal';

/**
 * The household's one grocery list as the app writes and reads it
 * (groceries ADR-0002; assistants ADR-0005): `groceryItems/{id}` with every
 * key the Dart `GroceryItem.toJson` writes for a typed item, plus `addedVia`
 * on what an assistant added. An assistant's item is typed, never planned,
 * so it carries no source fields and the plans never touch it; it has no
 * `productMatch` until a member picks one in the app.
 */
export const GROCERY_ITEMS = 'groceryItems';

/** As many items as the app's own list reads. */
export const GROCERY_READ_LIMIT = 200;

/** Unbought items read to find the same name; more than any list holds. */
export const UNBOUGHT_READ_LIMIT = 500;

/** The keys every typed item carries, as the app writes them. */
export const GROCERY_ITEM_KEYS = [
  'name',
  'quantity',
  'addedBy',
  'addedAt',
  'boughtAt',
  'boughtBy',
  'sourceKey',
  'sourceWeek',
  'sourceNote',
] as const;

export const storedGroceryItem = z.object({
  name: z.string(),
  quantity: z.string().nullable().optional(),
  addedBy: z.string(),
  boughtBy: z.string().nullable().optional(),
  sourceKey: z.string().nullable().optional(),
  addedVia: z.enum(ASSISTANT_VIAS).optional().catch(undefined),
});
export type StoredGroceryItem = z.infer<typeof storedGroceryItem>;

export function groceryItemsOf(store: Firestore, householdId: string): CollectionReference {
  return store.collection(HOUSEHOLDS).doc(householdId).collection(GROCERY_ITEMS);
}

/** Bought is decided by who bought it, as the app decides it. */
export function isBought(item: StoredGroceryItem): boolean {
  return item.boughtBy !== null && item.boughtBy !== undefined;
}

export function isPlanned(item: StoredGroceryItem): boolean {
  return item.sourceKey !== null && item.sourceKey !== undefined;
}

/** The names an item answers to: what was typed, and the key it was planned under. */
export function keysOf(item: StoredGroceryItem): string[] {
  const { sourceKey } = item;
  return sourceKey === null || sourceKey === undefined
    ? [normalisedName(item.name)]
    : [normalisedName(item.name), sourceKey];
}

/** The rules' text-edit test: an admin, whoever added it, or anybody for a planned item. */
export function mayEdit(access: AssistantMember, item: StoredGroceryItem): boolean {
  return access.role === 'admin' || item.addedBy === access.memberId || isPlanned(item);
}

/** The rules' delete test: an admin, whoever added it, or anybody for an unbought planned item. */
export function mayRemove(access: AssistantMember, item: StoredGroceryItem): boolean {
  return (
    access.role === 'admin' ||
    item.addedBy === access.memberId ||
    (isPlanned(item) && !isBought(item))
  );
}

/** An item as a tool answers with it. */
export const toolGroceryItem = z.object({
  id: z.string(),
  name: z.string(),
  quantity: z.string().nullable(),
  bought: z.boolean(),
  added_by: z.string(),
  added_via: z.enum(ASSISTANT_VIAS).nullable(),
  from_plans: z.boolean(),
});
export type ToolGroceryItem = z.infer<typeof toolGroceryItem>;

export function toToolItem(id: string, item: StoredGroceryItem): ToolGroceryItem {
  return {
    id,
    name: item.name,
    quantity: item.quantity ?? null,
    bought: isBought(item),
    added_by: item.addedBy,
    added_via: item.addedVia ?? null,
    from_plans: isPlanned(item),
  };
}
