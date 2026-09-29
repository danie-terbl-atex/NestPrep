import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';
import { z } from 'zod';

import { db } from '../shared/firestore';
import { readHousehold, roleOf } from '../household/documents';
import { refuse } from '../household/errors';
import { findClaimedMember } from '../household/membership';
import { parseInput, requireUid } from '../household/parse_input';
import { settleReferralAfter } from '../referrals/referral_settlement';
import { stageMemberActive } from './household_week_ledger';
import { countingZoneFor, weekKeyOf } from './iso_week';

export const recordActivityInput = z.object({
  householdId: z.string().trim().min(1).max(64),
});

/**
 * "I opened the app with this household" — the whole of what makes a member
 * active (product-analytics ADR-0001).
 *
 * The client says only *which household*. Who the member is comes from the
 * token and the household's own membership, so no client can make somebody
 * else active or count itself twice (`BE-03`). A household the caller is not in
 * is refused as `notAMember` whether or not it exists, so this call cannot be
 * used to learn which household ids are real.
 *
 * Idempotent: the member is added to a set, so the app calling twice in a day —
 * or a retry — changes nothing.
 */
export const recordActivity = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const { householdId } = parseInput(recordActivityInput, request.data);
  const store = db();

  const week = await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, householdId, () =>
      refuse('notAMember'),
    );
    if (roleOf(household, uid) === undefined) throw refuse('notAMember');
    const member = await findClaimedMember(transaction, store, householdId, uid);
    if (member === null) throw refuse('notAMember');

    const counted = weekKeyOf(new Date(), countingZoneFor(household.timeZone));
    stageMemberActive(transaction, store, { householdId, memberId: member.id, week: counted });
    return counted;
  });

  logger.info('activity recorded', { householdId, week });
  // Opening the app is also how a referred household shows it is a family
  // (subscriptions ADR-0002). Asked after, and never failing, the count.
  await settleReferralAfter(store, householdId, { kind: 'opened', uid }, new Date());
  return { week };
});
