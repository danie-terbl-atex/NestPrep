import type { Firestore } from 'firebase-admin/firestore';

import { readFlag } from '../shared/feature_flags';
import { billingCallerIn } from '../subscriptions/billing_caller';
import { refuseReferral } from './errors';

/**
 * Who may share or enter a code: family in the household, while referrals are
 * switched on (subscriptions ADR-0002, foundation ADR-0014). The caller is
 * re-derived from Firestore, never taken from the request (`BE-03`); like
 * buying, it is the family's decision, not a helper's, carer's or kid's.
 */
export async function requireReferringFamily(
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<void> {
  if (!(await readFlag(store, 'referralRewards'))) throw refuseReferral('referralsOff');
  const caller = await billingCallerIn(store, householdId, uid);
  if (!caller.isFamily) throw refuseReferral('onlyFamilyCanRefer');
}
