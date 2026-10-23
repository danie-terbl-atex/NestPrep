import { z } from 'zod';

import { LUNCH_SLOTS } from '../plan_week/week_documents';

/**
 * A ready-made starter box as NestPrep writes it in source (lunch-box
 * ADR-0018): each compartment names a recipe or a starter-catalogue quick pick
 * by id, never by name — the name and allergen codes are copied from that
 * source when the box is published, so they are typed once.
 */

export const LUNCH_STARTER_BOXES = 'lunchStarterBoxes';

/** The app reads `status == published` ordered by `order`, at most this many. */
export const MAX_STARTER_BOXES = 20;

const slug = z
  .string()
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/)
  .max(60);

const pickSource = z.discriminatedUnion('kind', [
  z.object({ kind: z.literal('recipe'), recipeId: slug }).strict(),
  z.object({ kind: z.literal('quickPick'), seedKey: slug }).strict(),
]);
export type StarterPickSource = z.infer<typeof pickSource>;

export const starterBoxSource = z
  .object({
    id: slug,
    name: z.string().trim().min(1).max(40),
    blurb: z.string().trim().min(1).max(140),
    order: z.number().int().min(0).max(1000),
    picks: z.partialRecord(z.enum(LUNCH_SLOTS), pickSource),
  })
  .strict()
  .refine((box) => Object.keys(box.picks).length > 0, {
    message: 'a starter box fills at least one compartment',
    path: ['picks'],
  });
export type StarterBoxSource = z.infer<typeof starterBoxSource>;
