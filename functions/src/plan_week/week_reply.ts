import { z } from 'zod';

import type { WeekBrief, WeekBriefProduct } from './week_brief';
import { slotKey, type LunchSlot } from './week_documents';

/**
 * The model's answer, each entry checked on its own so an odd one costs only
 * itself (ENG-09). Bounded here because Vertex will not take `maxItems`.
 */
export const MAX_REPLY_LUNCHES = 5 * 5 * 12;
export const MAX_REPLY_PACKS = 25 * 6;
export const MAX_BOXES_PER_PACK = 100;

export const weekReply = z.object({
  packs: z.array(z.unknown()).transform((list) => list.slice(0, MAX_REPLY_PACKS)),
  lunches: z.array(z.unknown()).transform((list) => list.slice(0, MAX_REPLY_LUNCHES)),
});
export type WeekReply = z.infer<typeof weekReply>;

const replyPack = z.object({ product: z.string(), boxesPerPack: z.number() });
const replyLunch = z.object({
  child: z.string(),
  day: z.number().int().min(1).max(5),
  slot: z.string(),
  product: z.string(),
});

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

export interface ProposedWeek {
  readonly lunches: readonly ProposedLunch[];
  readonly packs: readonly ProposedPack[];
  readonly dropped: number;
}

/**
 * Every choice checked (lunch-box ADR-0012): a product the brief offered, in
 * the compartment its idea is for, for a child that product may go to, in a
 * compartment that child has open and nobody else in the reply took — a treat
 * on Friday only. Anything else is dropped and counted. Every product used
 * gets a pack size: the model's, else the pack's own count, else one.
 */
export function weekFrom(reply: WeekReply, brief: WeekBrief): ProposedWeek {
  const productByRef = new Map(brief.products.map((product) => [product.ref, product]));
  const childByRef = new Map(brief.children.map((child) => [child.ref, child]));
  const taken = new Set<string>();
  const lunches: ProposedLunch[] = [];
  let dropped = 0;

  for (const entry of reply.lunches) {
    const lunch = replyLunch.safeParse(entry);
    const product = lunch.success ? productByRef.get(lunch.data.product) : undefined;
    const child = lunch.success ? childByRef.get(lunch.data.child) : undefined;
    if (!lunch.success || product === undefined || child === undefined) {
      dropped += 1;
      continue;
    }
    const { day, slot } = lunch.data;
    const key = `${child.ref}|${slotKey(day, slot)}`;
    const fits =
      product.slot === slot &&
      product.childRefs.includes(child.ref) &&
      child.open.includes(slotKey(day, slot)) &&
      (slot !== 'treat' || day === 5) &&
      !taken.has(key);
    if (!fits) {
      dropped += 1;
      continue;
    }
    taken.add(key);
    lunches.push({
      childId: child.memberId,
      day,
      slot: product.slot,
      ideaId: product.ideaId,
      productId: product.product.productId,
    });
  }

  return { lunches, packs: packsFor(lunches, reply, productByRef), dropped };
}

function packsFor(
  lunches: readonly ProposedLunch[],
  reply: WeekReply,
  productByRef: ReadonlyMap<string, WeekBriefProduct>,
): ProposedPack[] {
  const stated: Record<string, number> = {};
  for (const entry of reply.packs) {
    const pack = replyPack.safeParse(entry);
    const product = pack.success ? productByRef.get(pack.data.product) : undefined;
    if (!pack.success || product === undefined) continue;
    if (!Number.isFinite(pack.data.boxesPerPack)) continue;
    stated[product.product.productId] ??= clampBoxes(pack.data.boxesPerPack);
  }
  const used = [...new Set(lunches.map((lunch) => lunch.productId))];
  return used.map((productId) => {
    const own = [...productByRef.values()].find((p) => p.product.productId === productId);
    return {
      productId,
      boxesPerPack: stated[productId] ?? own?.product.packQuantity ?? 1,
    };
  });
}

function clampBoxes(value: number): number {
  return Math.min(MAX_BOXES_PER_PACK, Math.max(1, Math.round(value)));
}
