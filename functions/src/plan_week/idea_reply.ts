import { z } from 'zod';

import { exclusionFor, type Exclusion } from './child_exclusion';
import { normalised } from './food_safety';
import type { IdeaBrief } from './idea_brief';
import { MAX_IDEAS } from './schemas';
import { isLunchSlot, type LunchSlot } from './week_documents';

/** The model's answer, one entry at a time so an odd entry costs only itself (ENG-09). */
export const ideasReply = z.object({
  ideas: z.array(z.unknown()).transform((list) => list.slice(0, MAX_IDEAS * 2)),
});
export type IdeasReply = z.infer<typeof ideasReply>;

const replyIdea = z.object({
  slot: z.string(),
  idea: z.string().trim().min(1),
  searchTerm: z.string().trim().optional().default(''),
  children: z.array(z.unknown()).optional().default([]),
  why: z.string().trim().optional().default(''),
});

export interface ChildExclusion extends Exclusion {
  readonly childId: string;
}

/** One idea as the phone shows it: who it is still for, and who it was struck out for and why. */
export interface LunchIdea {
  readonly id: string;
  readonly slot: LunchSlot;
  readonly idea: string;
  readonly searchTerm: string;
  readonly why: string;
  readonly childIds: readonly string[];
  readonly excluded: readonly ChildExclusion[];
}

/**
 * The model's ideas, checked: a known compartment, children it names that
 * have that compartment open (every such child when it names none), and then
 * — per child — struck out when its words name one of their allergens, a
 * free-text allergy or a dislike. An idea struck out for everybody is kept,
 * so the phone can show it crossed through with the reason (lunch-box
 * ADR-0012). The same search twice in a compartment is one idea.
 */
export function ideasFrom(reply: IdeasReply, brief: IdeaBrief): LunchIdea[] {
  const ideas: LunchIdea[] = [];
  const seen = new Set<string>();
  for (const entry of reply.ideas) {
    if (ideas.length >= MAX_IDEAS) break;
    const parsed = replyIdea.safeParse(entry);
    if (!parsed.success || !isLunchSlot(parsed.data.slot)) continue;
    const slot = parsed.data.slot;
    const idea = parsed.data.idea.slice(0, 60);
    const searchTerm = (parsed.data.searchTerm || idea).slice(0, 60);
    const key = `${slot}|${normalised(searchTerm)}`;
    if (seen.has(key)) continue;

    const withRoom = brief.children.filter((child) => child.open[slot] > 0);
    const named = new Set(parsed.data.children.filter((ref) => typeof ref === 'string'));
    const forWhom = withRoom.some((child) => named.has(child.ref))
      ? withRoom.filter((child) => named.has(child.ref))
      : withRoom;
    if (forWhom.length === 0) continue;
    seen.add(key);

    const text = `${idea} ${searchTerm}`;
    const childIds: string[] = [];
    const excluded: ChildExclusion[] = [];
    for (const child of forWhom) {
      const exclusion = exclusionFor(child.rules, text);
      if (exclusion === null) childIds.push(child.memberId);
      else excluded.push({ childId: child.memberId, ...exclusion });
    }
    ideas.push({
      id: `idea-${String(ideas.length + 1)}`,
      slot,
      idea,
      searchTerm,
      why: parsed.data.why.slice(0, 140),
      childIds,
      excluded,
    });
  }
  return ideas;
}
