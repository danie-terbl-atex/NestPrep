import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { DECISION_SECRETS } from '../ai/ai_config';
import { decisionRuntime } from '../ai/ai_runtime';
import { runDecisionCall } from '../ai/run_decision_call';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { openPlanning } from './plan_gate';
import { buildLunchWeekInput } from './schemas';
import {
  assembleWeek,
  type ProposedDish,
  type ProposedLunch,
  type ProposedPack,
} from './week_assembly';
import { weekBriefFrom } from './week_brief';
import { weekDecisionRequest, weekDecisionsFrom } from './week_decisions';

export interface BuildLunchWeekResult {
  readonly week: string;
  readonly lunches: readonly ProposedLunch[];
  readonly packs: readonly ProposedPack[];
  /** Dishes placed and the store products each is bought as (lunch-box ADR-0021); additive. */
  readonly dishes: readonly ProposedDish[];
  readonly budgetCents: number | null;
  /** Products no child may have after all. */
  readonly dropped: number;
  /** Null when there was nothing to ask the model, so nothing was spent. */
  readonly callsLeft: number | null;
}

/**
 * *Plan my week*, step four (lunch-box ADR-0012, foundation ADR-0021): Jev
 * scores how well each product the phone found fits its compartment and how
 * many boxes a pack does; `assembleWeek` builds the week against the budget.
 * A dish (ADR-0021) is placed like a product and costed as its ingredients.
 * **Nothing is written here.** Every product is checked against each child's
 * rules before Jev sees it (`week_brief.ts`).
 */
export const buildLunchWeek = onCall(
  { timeoutSeconds: 60, memory: '512MiB', secrets: DECISION_SECRETS },
  async (request): Promise<BuildLunchWeekResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(buildLunchWeekInput, request.data);
    const store = db();
    const { caller, monday, today, facts, children } = await openPlanning(store, input, uid);

    const brief = weekBriefFrom(
      input.ideas,
      children,
      { monday, today, plans: facts.plans, budgetCents: facts.budgetCents, prices: facts.prices },
      { slots: input.slots, preferences: input.preferences, treatDays: input.treatDays },
    );
    const empty = {
      week: input.week,
      lunches: [],
      packs: [],
      dishes: [],
      budgetCents: facts.budgetCents,
      dropped: brief.removed,
      callsLeft: null,
    };
    // Nothing open, or nothing any child may have: an answer that costs nothing.
    if (brief.children.length === 0 || brief.products.length === 0) {
      // Counts only (ENG-22) — so an empty week is visible in the log.
      logger.info('lunch week empty', {
        householdId: input.householdId,
        week: input.week,
        children: children.length,
        childrenOpen: brief.children.length,
        productsOffered: brief.products.length,
        removed: brief.removed,
        alreadyPacked: brief.alreadyInWeek.length,
        slots: input.slots.length,
      });
      return empty;
    }

    const result = await runDecisionCall(await decisionRuntime(store), {
      feature: 'planMyWeek',
      householdId: input.householdId,
      timeZone: caller.timeZone,
      uid,
      request: weekDecisionRequest(brief),
    });
    const proposal = assembleWeek(brief, weekDecisionsFrom(result.value, brief));

    // Counts only: never a product, a food or anybody's name (ENG-22).
    logger.info('lunch week built', {
      householdId: input.householdId,
      week: input.week,
      children: children.length,
      productsOffered: brief.products.length,
      slots: input.slots.length,
      preferences: input.preferences.length,
      treatDays: input.treatDays.length,
      lunches: proposal.lunches.length,
      dishes: proposal.dishes.length,
      dropped: brief.removed,
      alreadyPacked: brief.alreadyInWeek.length,
      overBudget: facts.budgetCents !== null && proposal.weekCents > facts.budgetCents,
    });
    return {
      week: input.week,
      lunches: proposal.lunches,
      packs: proposal.packs,
      dishes: proposal.dishes,
      budgetCents: facts.budgetCents,
      dropped: brief.removed,
      callsLeft: result.callsLeft,
    };
  },
);
