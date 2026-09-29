import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { redeemReferral } from './redemption';
import { requireReferringFamily } from './referral_caller';
import { redeemReferralCodeInput } from './schemas';

/**
 * A new household entering the code another family shared (subscriptions
 * ADR-0002). Nothing is given yet: the answer is the date by which the new
 * household has to become a real family for both to get their month.
 */
export const redeemReferralCode = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(redeemReferralCodeInput, request.data);
  const store = db();
  await requireReferringFamily(store, input.householdId, uid);
  const { qualifyBy } = await redeemReferral(
    store,
    { householdId: input.householdId, uid, code: input.code },
    new Date(),
  );
  logger.info('referral code redeemed', { householdId: input.householdId });
  return { qualifyBy: qualifyBy.toISOString() };
});
