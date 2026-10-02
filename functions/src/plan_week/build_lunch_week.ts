import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { aiRuntime } from '../ai/ai_runtime';
import { runAiCall } from '../ai/run_ai_call';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { basketCents, basketLines } from './basket';
import { openPlanning } from './plan_gate';
import { buildLunchWeekInput } from './schemas';
import { weekBriefFrom } from './week_brief';
import { weekRequest } from './week_prompt';
import { weekFrom, weekReply, type ProposedLunch, type ProposedPack } from './week_reply';

export interface BuildLunchWeekResult {
  readonly week: string;
  readonly lunches: readonly ProposedLunch[];
  readonly packs: readonly ProposedPack[];
  readonly budgetCents: number | null;
  /** Choices the model made that did not fit, and products no child may have after all. */
  readonly dropped: number;
  /** Null when there was nothing to ask the model, so nothing was spent. */
  readonly callsLeft: number | null;
}

/**
 * *Plan my week*, step four (lunch-box ADR-0012): from the products the phone
 * found at the store for each idea, the model chooses what goes in every open
 * compartment and how many boxes a pack does, against the household's weekly
 * budget as a till total. **Nothing is written here.** Every product is
 * checked against each child's rules before the model sees it and every
 * choice after (`week_brief.ts`, `week_reply.ts`); the phone shows the basket,
 * the parent swaps what they like, and the plan is saved through the ordinary
 * lunch writes, under the rules' allergy refusal.
 *
 * Who may, premium, the switch and the cap: as `draftLunchIdeas`, through
 * `openPlanning`. Sixty seconds and 512 MiB.
 */
export const buildLunchWeek = onCall(
  { timeoutSeconds: 60, memory: '512MiB' },
  async (request): Promise<BuildLunchWeekResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(buildLunchWeekInput, request.data);
    const store = db();
    const { caller, monday, facts, children } = await openPlanning(store, input, uid);

    const brief = weekBriefFrom(input.ideas, children, facts.plans, monday, facts.budgetCents);
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

    const result = await runAiCall(await aiRuntime(store), {
      feature: 'planMyWeek',
      householdId: input.householdId,
      timeZone: caller.timeZone,
      uid,
      request: weekRequest(brief),
      schema: weekReply,
    });
    const proposal = weekFrom(result.value, brief);

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
      lunches: proposal.lunches.length,
      dropped: proposal.dropped + brief.removed,
      overBudget: facts.budgetCents !== null && basket > facts.budgetCents,
    });
    return {
      week: input.week,
      lunches: proposal.lunches,
      packs: proposal.packs,
      budgetCents: facts.budgetCents,
      dropped: proposal.dropped + brief.removed,
      callsLeft: result.callsLeft,
    };
  },
);
