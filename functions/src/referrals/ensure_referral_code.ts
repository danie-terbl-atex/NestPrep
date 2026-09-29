import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { requireReferringFamily } from './referral_caller';
import { ensureReferralCode as ensureCode } from './referral_code';
import { ensureReferralCodeInput } from './schemas';

/**
 * The household's own referral code, made on first ask and the same ever
 * after (subscriptions ADR-0002). The app shows it and shares it; the code
 * itself is written only here, so no phone can pick one.
 */
export const ensureReferralCode = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const { householdId } = parseInput(ensureReferralCodeInput, request.data);
  const store = db();
  await requireReferringFamily(store, householdId, uid);
  const code = await ensureCode(store, { householdId }, new Date());
  logger.info('referral code ready', { householdId });
  return { code };
});
