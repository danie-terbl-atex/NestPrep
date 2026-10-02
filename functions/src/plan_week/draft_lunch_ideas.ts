import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { aiRuntime } from '../ai/ai_runtime';
import { runAiCall } from '../ai/run_ai_call';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { hasOpenCompartments, ideaBriefFrom } from './idea_brief';
import { ideasRequest } from './idea_prompt';
import { ideasFrom, ideasReply, type LunchIdea } from './idea_reply';
import { openPlanning } from './plan_gate';
import { draftLunchIdeasInput } from './schemas';

export interface DraftLunchIdeasResult {
  readonly week: string;
  readonly budgetCents: number | null;
  readonly ideas: readonly LunchIdea[];
  /** Null when there was nothing to ask the model, so nothing was spent. */
  readonly callsLeft: number | null;
}

/**
 * *Plan my week*, step two (lunch-box ADR-0012): the model drafts a short
 * shopping list of lunch ideas for the chosen children — each with the words
 * to search the store for — from what they like, dislike, ate and left, and
 * the household's weekly budget. **Nothing is written, and the model never
 * hears an allergy**: NestPrep strikes an idea out per child afterwards when
 * its words name one of their allergens, a free-text allergy or a dislike,
 * and says why, so the parent sees exactly what was taken out.
 *
 * Who may: the household's `lunch` grant at edit. Premium, behind the
 * `planMyWeek` switch, one of the household's monthly AI calls (foundation
 * ADR-0015) — all in `openPlanning`.
 *
 * Sixty seconds and 512 MiB, as every call that waits on Vertex.
 */
export const draftLunchIdeas = onCall(
  { timeoutSeconds: 60, memory: '512MiB' },
  async (request): Promise<DraftLunchIdeasResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(draftLunchIdeasInput, request.data);
    const store = db();
    const { caller, monday, facts, children } = await openPlanning(store, input, uid);

    const brief = ideaBriefFrom(children, facts.plans, monday, facts.budgetCents, input.aisle);
    if (!hasOpenCompartments(brief)) {
      // A week already packed is an answer, and costs the household nothing.
      return { week: input.week, budgetCents: facts.budgetCents, ideas: [], callsLeft: null };
    }

    const result = await runAiCall(await aiRuntime(store), {
      feature: 'planMyWeek',
      householdId: input.householdId,
      timeZone: caller.timeZone,
      uid,
      request: ideasRequest(brief),
      schema: ideasReply,
    });
    const ideas = ideasFrom(result.value, brief);

    // Counts only: never an idea, a food or anybody's name (ENG-22).
    logger.info('lunch ideas drafted', {
      householdId: input.householdId,
      week: input.week,
      children: children.length,
      aisleShelves: brief.aisle.length,
      ideas: ideas.length,
      struckOut: ideas.reduce((sum, idea) => sum + idea.excluded.length, 0),
    });
    return {
      week: input.week,
      budgetCents: facts.budgetCents,
      ideas,
      callsLeft: result.callsLeft,
    };
  },
);
