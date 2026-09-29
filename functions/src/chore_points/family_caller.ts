import type { Firestore, Transaction } from 'firebase-admin/firestore';

import { readHousehold, roleOf } from '../household/documents';
import { isFamilyRole } from './chore_eligibility';
import { refusePoints } from './errors';

/**
 * The caller as a parent of this household, or the refusal that says they are
 * not (todos ADR-0003). Stars are given and rewards handed over by family —
 * admin, parent, or the legacy `member` — whatever a helper's or a claimed
 * kid's grant on to-dos says. A kid device never gets here: `requireUid`
 * refused its token first.
 *
 * Returns the profile the caller claimed, which is what a settled claim or
 * request records as who settled it; null for an account claimed before
 * profiles were recorded.
 */
export async function requireFamily(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<{ memberId: string | null; timeZone: string }> {
  const household = await readHousehold(transaction, store, householdId, () =>
    refusePoints('notAMember'),
  );
  const role = roleOf(household, uid);
  if (role === undefined) throw refusePoints('notAMember');
  if (!isFamilyRole(role)) throw refusePoints('notFamily');
  const memberId = household.profiles?.[uid];
  return {
    memberId: typeof memberId === 'string' ? memberId : null,
    timeZone: typeof household.timeZone === 'string' ? household.timeZone : 'UTC',
  };
}
