import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { DECISION_SECRETS } from '../ai/ai_config';
import { decisionRuntime } from '../ai/ai_runtime';
import { runDecisionCall } from '../ai/run_decision_call';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { basketCents, basketLines } from './basket';
import { openPlanning } from './plan_gate';
import { buildLunchWeekInput } from './schemas';
import { assembleWeek, type ProposedLunch, type ProposedPack } from './week_assembly';
import { weekBriefFrom } from './week_brief';
import { weekDecisionRequest, weekDecisionsFrom } from './week_decisions';

export interface BuildLunchWeekResult {
  readonly week: string;
  readonly lunches: readonly ProposedLunch[];
  readonly packs: readonly ProposedPack[];
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
 * **Nothing is written here.** Every product is checked against each child's
 * rules before Jev sees it (`week_brief.ts`).
 */
export const buildLunchWeek = onCall(
  { timeoutSeconds: 60, memory: '512MiB', secrets: DECISION_SECRETS },
  async (request): Promise<BuildLunchWeekResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(buildLunchWeekInput, request.data);
    const store = db();
    const { caller, monday, facts, children } = await openPlanning(store, input, uid);

    const brief = weekBriefFrom(input.ideas, children, facts.plans, monday, facts.budgetCents, {
      slots: input.slots,
      preferences: input.preferences,
    });
    const empty = {
      week: input.week,
      lunches: [],
      packs: [],
      budgetCents: facts.budgetCents,
      dropped: brief.removed,
      callsLeft: null,
    };
    // Nothing open, or nothing any child may have: an answer that costs nothing.
    if (brief.children.length === 0 || brief.products.length === 0) return empty;

    const result = await runDecisionCall(await decisionRuntime(store), {
      feature: 'planMyWeek',
      householdId: input.householdId,
      timeZone: caller.timeZone,
      uid,
      request: weekDecisionRequest(brief),
    });
    const proposal = assembleWeek(brief, weekDecisionsFrom(result.value, brief));

    const prices = new Map(
      brief.products.map(({ product }) => [product.productId, product.priceCents]),
    );
    const basket = basketCents(
      basketLines(
        proposal.lunches,
        proposal.packs.map((pack) => ({ ...pack, priceCents: prices.get(pack.productId) ?? 0 })),
      ),
    );
    // Counts only: never a product, a food or anybody's name (ENG-22).
    logger.info('lunch week built', {
      householdId: input.householdId,
      week: input.week,
      children: children.length,
      productsOffered: brief.products.length,
      slots: input.slots.length,
      preferences: input.preferences.length,
      lunches: proposal.lunches.length,
      dropped: brief.removed,
      overBudget: facts.budgetCents !== null && basket > facts.budgetCents,
    });
    return {
      week: input.week,
      lunches: proposal.lunches,
      packs: proposal.packs,
      budgetCents: facts.budgetCents,
      dropped: brief.removed,
      callsLeft: result.callsLeft,
    };
  },
);
