import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { readHousehold, roleOf } from '../household/documents';
import { refuse } from '../household/errors';
import { findClaimedMember } from '../household/membership';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { CONVERSION_TRIGGERS } from './conversion_ledger';
import { stageLastPaywall } from './household_cohort_ledger';
import { stagePaywallOpened } from './household_week_ledger';
import { countingZoneFor, weekKeyOf } from './iso_week';

export const recordPaywallOpenedInput = z.object({
  householdId: z.string().trim().min(1).max(64),
  trigger: z.enum(CONVERSION_TRIGGERS),
});

/**
 * "The paywall opened on this feature" — the denominator of conversion by
 * trigger, and what a purchase that follows is attributed to
 * (product-analytics ADR-0002).
 *
 * The client says only which household and which trigger, from a closed
 * list. Whether the caller is in the household is re-derived from the token
 * and the membership (`BE-03`); a household the caller is not in is refused
 * as `notAMember` whether or not it exists, like `recordActivity`.
 */
export const recordPaywallOpened = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const { householdId, trigger } = parseInput(recordPaywallOpenedInput, request.data);
  const store = db();
  const now = new Date();

  const week = await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, householdId, () =>
      refuse('notAMember'),
    );
    if (roleOf(household, uid) === undefined) throw refuse('notAMember');
    if ((await findClaimedMember(transaction, store, householdId, uid)) === null) {
      throw refuse('notAMember');
    }

    // The cohort entry is read before anything is written (a transaction's rule).
    await stageLastPaywall(transaction, store, {
      householdId,
      createdAt: household['createdAt'],
      timeZone: household.timeZone,
      trigger,
      openedAt: now,
    });
    const counted = weekKeyOf(now, countingZoneFor(household.timeZone));
    stagePaywallOpened(transaction, store, { householdId, week: counted, trigger });
    return counted;
  });

  logger.info('paywall opening recorded', { householdId, trigger, week });
  return { week };
});
