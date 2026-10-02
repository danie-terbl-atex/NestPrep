import { z } from 'zod';

import { LUNCH_SLOTS } from './week_documents';

/** A household has a handful of children; this bounds the request (BE-08). */
export const MAX_PLANNED_CHILDREN = 12;
/** A week's shopping list of lunch ideas, and what one idea may bring from the store. */
export const MAX_IDEAS = 25;
export const MAX_PRODUCTS_PER_IDEA = 6;
/** Checkers' own lunchbox shelves the phone read, and the names it sends from each (lunch-box ADR-0013). */
export const MAX_AISLE_SHELVES = 12;
export const MAX_AISLE_NAMES = 6;
/** The model's ideas and the shelves together, as the phone sends them back with products. */
export const MAX_FOUND_IDEAS = MAX_IDEAS + MAX_AISLE_SHELVES;

const householdId = z.string().trim().min(1).max(64);
const week = z.string().regex(/^\d{4}-W\d{2}$/);
const memberId = z.string().trim().min(1).max(128);
const childIds = z.array(memberId).min(1).max(MAX_PLANNED_CHILDREN);

/**
 * One shelf of Checkers' Kids Lunchbox range the phone read (lunch-box
 * ADR-0013): the compartment it fills, its title, and the names of the best
 * products it kept there — store words only.
 */
export const aisleShelf = z.object({
  slot: z.enum(LUNCH_SLOTS),
  title: z.string().trim().min(1).max(60),
  products: z.array(z.string().trim().min(1).max(120)).max(MAX_AISLE_NAMES),
});
export type AisleShelf = z.infer<typeof aisleShelf>;

/**
 * Drafting the week's lunch ideas, parsed at the edge (ENG-09, BE-03): the
 * week, whose lunches and the shelves the phone read — never anything about a
 * child (lunch-box ADR-0012, ADR-0013).
 */
export const draftLunchIdeasInput = z.object({
  householdId,
  week,
  childIds,
  aisle: z.array(aisleShelf).max(MAX_AISLE_SHELVES).optional().default([]),
});
export type DraftLunchIdeasInput = z.infer<typeof draftLunchIdeasInput>;

/**
 * One product the phone found at the store for an idea, already filtered
 * there; the server checks it again before the model sees it.
 */
export const foundProduct = z.object({
  productId: z.string().trim().min(1).max(64),
  name: z.string().trim().min(1).max(120),
  brand: z.string().trim().max(60).nullable(),
  priceCents: z.number().int().min(0).max(500_000),
  isOnPromotion: z.boolean(),
  allergens: z.array(z.string().max(32)).max(20),
  allergensKnown: z.boolean(),
  packQuantity: z.number().int().min(1).max(100).nullable(),
});
export type FoundProduct = z.infer<typeof foundProduct>;

export const foundIdea = z.object({
  id: z.string().trim().min(1).max(32),
  slot: z.enum(LUNCH_SLOTS),
  childIds: z.array(memberId).max(MAX_PLANNED_CHILDREN),
  products: z.array(foundProduct).max(MAX_PRODUCTS_PER_IDEA),
  /** A shelf of Checkers' lunchbox range rather than a model idea (lunch-box ADR-0013). */
  fromAisle: z.boolean().optional().default(false),
});
export type FoundIdea = z.infer<typeof foundIdea>;

/** Building the week from what the store has, as the phone found it. */
export const buildLunchWeekInput = z.object({
  householdId,
  week,
  childIds,
  ideas: z.array(foundIdea).max(MAX_FOUND_IDEAS),
});
export type BuildLunchWeekInput = z.infer<typeof buildLunchWeekInput>;
