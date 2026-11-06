import { onCall } from 'firebase-functions/v2/https';

import { DECISION_SECRETS } from '../ai/ai_config';
import { decisionRuntime } from '../ai/ai_runtime';
import { askDecisions } from '../ai/run_decision_call';
import { householdRef } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { isOffShift } from '../household/shift_window';
import { db } from '../shared/firestore';
import { requireGroceryReader } from './checkers_caller';
import { readFlag, type FeatureFlag } from '../shared/feature_flags';
import { refuseCheckers } from './errors';
import { matchRequest, rankedFrom, type RankedMatch } from './match_decisions';
import { rankProductMatchesInput } from './schemas';

const SHOP_SWITCHES: readonly FeatureFlag[] = ['addToCheckers', 'addToPnp', 'addToWoolworths'];

/**
 * Jev's view of which shop products — Checkers', Pick n Pay's or Woolworths' —
 * a grocery line means (foundation ADR-0021, add-to-pnp ADR-0007). Only names and prices go out; the member still picks.
 */
export const rankProductMatches = onCall(
  { secrets: DECISION_SECRETS },
  async (request): Promise<{ ranked: RankedMatch[] }> => {
    const uid = requireUid(request.auth);
    const input = parseInput(rankProductMatchesInput, request.data);
    const store = db();
    const household = await householdRef(store, input.householdId).get();
    if (!household.exists) throw refuseCheckers('not-a-member');
    requireGroceryReader(household.data(), uid);
    if (await isOffShift(store, input.householdId, household.data(), uid, new Date())) {
      throw refuseCheckers('not-a-member');
    }
    const switches = await Promise.all(SHOP_SWITCHES.map((flag) => readFlag(store, flag)));
    if (!switches.some(Boolean)) throw refuseCheckers('checkers-switched-off');
    const answers = await askDecisions(
      await decisionRuntime(store),
      'productMatch',
      matchRequest(input),
    );
    return { ranked: rankedFrom(answers, input) };
  },
);
