import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { aiRuntime } from '../ai/ai_runtime';
import { CURRENT_ENTITLEMENT, ENTITLEMENT } from '../ai/firestore_usage_ledger';
import { runAiCall } from '../ai/run_ai_call';
import { tierFrom } from '../ai/usage_rules';
import { householdRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { addDays, todayIn } from '../school_letter/plain_date';
import { readFlag } from '../shared/feature_flags';
import { db } from '../shared/firestore';
import { premiumRequired } from '../subscriptions/errors';
import { refusePlanWeek } from './errors';
import { mondayOfWeek } from './iso_week';
import { briefFrom } from './plan_brief';
import { planCallerIn } from './plan_caller';
import { planRequest } from './plan_prompt';
import { planReply, proposalFrom, type ProposedDinner, type ProposedLunch } from './plan_reply';
import { planMyWeekInput } from './schemas';
import { readWeekFacts } from './week_reads';

export interface PlanMyWeekResult {
  readonly week: string;
  readonly lunches: readonly ProposedLunch[];
  readonly dinners: readonly ProposedDinner[];
  readonly dinnersIncluded: boolean;
  readonly dropped: number;
  /** Null when there was nothing to ask the model, so nothing was spent. */
  readonly callsLeft: number | null;
}

/**
 * *Plan my week* (lunch-box ADR-0011): each chosen child's school lunches and
 * the family's dinners, proposed by the model from the household's own
 * library, what each child eats, their go-to boxes and — when asked — the
 * pantry and prices. **Nothing is written here.** The proposal goes back to
 * the app, where a parent looks it over, swaps what they like and saves it
 * through the ordinary lunch and meal-plan writes, under the ordinary rules —
 * the allergy refusal included.
 *
 * Who may: somebody the household's `lunch` grant lets change lunches;
 * dinners only for somebody the `meals` grant lets change the meal plan.
 * Premium (subscriptions ADR-0001) — checked here against the entitlement,
 * not only on the phone — behind its switch (foundation ADR-0014), and one of
 * the household's monthly AI calls (foundation ADR-0015).
 *
 * Unsafe items are removed before the model is asked, so it cannot choose
 * them, and every choice it makes is checked again after (`plan_reply.ts`).
 * The model sees placeholders and item names, never a child (`plan_brief.ts`).
 *
 * Sixty seconds and 512 MiB, as reading a school letter: a model planning a
 * week takes seconds, and the household's library is read whole (BE-19).
 */
export const planMyWeek = onCall(
  { timeoutSeconds: 60, memory: '512MiB' },
  async (request): Promise<PlanMyWeekResult> => {
    const uid = requireUid(request.auth);
    const input = parseInput(planMyWeekInput, request.data);
    const store = db();

    if (!(await readFlag(store, 'planMyWeek'))) throw refusePlanWeek('planWeekOff');
    const caller = await planCallerIn(store, input.householdId, uid);

    const monday = mondayOfWeek(input.week);
    const { today } = todayIn(caller.timeZone, new Date());
    if (monday === null || addDays(monday, 6) < today) throw refusePlanWeek('weekNotPlannable');

    const entitlement = await householdRef(store, input.householdId)
      .collection(ENTITLEMENT)
      .doc(CURRENT_ENTITLEMENT)
      .get();
    if (tierFrom(entitlement.data(), new Date()) !== 'premium') {
      throw premiumRequired('aiPlanning');
    }

    const withDinners = input.includeDinners && caller.mayPlanDinners;
    const facts = await readWeekFacts(store, input.householdId, {
      monday,
      withDinners,
      withPantry: input.useWhatsInTheHouse,
      withPrices: input.budget === 'thrifty',
    });
    const asked = new Set(input.childIds);
    const children = facts.children.filter((child) => asked.has(child.memberId));
    if (children.length === 0 && !withDinners) throw refusePlanWeek('nothingToPlan');

    const brief = briefFrom(facts, {
      monday,
      week: input.week,
      children,
      withDinners,
      usePantry: input.useWhatsInTheHouse,
      thrifty: input.budget === 'thrifty',
    });
    const nothingOpen =
      brief.children.every((child) => child.open.length === 0) && brief.dinnerDays.length === 0;
    if (nothingOpen) {
      // A week already full is an answer, and costs the household nothing.
      return {
        week: input.week,
        lunches: [],
        dinners: [],
        dinnersIncluded: withDinners,
        dropped: 0,
        callsLeft: null,
      };
    }

    const deps = await aiRuntime(store);
    const result = await runAiCall(deps, {
      feature: 'planMyWeek',
      householdId: input.householdId,
      timeZone: caller.timeZone,
      uid,
      request: planRequest(brief),
      schema: planReply,
    });
    const proposal = proposalFrom(
      result.value,
      brief,
      new Map(children.map((child) => [child.memberId, child.rules])),
      facts.everybody,
    );

    // Counts only: never an item, a meal or anybody's name (ENG-22).
    logger.info('week planned', {
      householdId: input.householdId,
      week: input.week,
      children: children.length,
      withDinners,
      usePantry: input.useWhatsInTheHouse,
      budget: input.budget,
      lunchesProposed: proposal.lunches.length,
      dinnersProposed: proposal.dinners.length,
      dropped: proposal.dropped,
    });
    return {
      week: input.week,
      lunches: proposal.lunches,
      dinners: proposal.dinners,
      dinnersIncluded: withDinners,
      dropped: proposal.dropped,
      callsLeft: result.callsLeft,
    };
  },
);
