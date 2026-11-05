import { z } from 'zod';

/** More than any list holds; the rest are dropped (BE-08). */
export const MAX_LINES = 60;

/** The grocery rules' own limits are wider; these keep a row readable. */
export const MAX_NAME_LENGTH = 100;
export const MAX_QUANTITY_LENGTH = 40;

export const listReply = z.object({
  items: z
    .array(
      z.object({
        name: z.string(),
        quantity: z.string().nullable().optional(),
      }),
    )
    .max(MAX_LINES * 2),
});
export type ListReply = z.infer<typeof listReply>;

/** One line the photo proposed — nothing is written until the member confirms it. */
export interface ListLine {
  readonly name: string;
  readonly quantity: string | null;
}

/**
 * The model's items as lines the app can trust: tidied, bounded, and each
 * name once — a list that says "milk" twice wants milk, not two rows.
 */
export function linesFrom(reply: ListReply): ListLine[] {
  const seen = new Set<string>();
  const lines: ListLine[] = [];
  for (const item of reply.items) {
    const name = tidy(item.name, MAX_NAME_LENGTH);
    if (name === null) continue;
    const key = name.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    lines.push({ name, quantity: tidy(item.quantity ?? null, MAX_QUANTITY_LENGTH) });
    if (lines.length === MAX_LINES) break;
  }
  return lines;
}

function tidy(value: string | null, max: number): string | null {
  const collapsed = value?.replace(/\s+/g, ' ').trim() ?? '';
  return collapsed === '' ? null : collapsed.slice(0, max);
}
