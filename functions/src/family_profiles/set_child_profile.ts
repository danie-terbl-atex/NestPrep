import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { householdRef, memberRef, readHousehold, roleOf } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { FREE_CHILD_PROFILES } from '../subscriptions/entitlement';
import { premiumRequired, refuseSubscription } from '../subscriptions/errors';
import { type SetChildProfileInput, setChildProfileInput } from '../subscriptions/schemas';
import { householdHasPremium } from '../subscriptions/subscription_documents';
import { FAMILY_PROFILES } from './member_details';

/**
 * Marks a member as a child, or not — the one write to `familyProfiles` a
 * client may not make itself, because it is what the free tier is counted
 * by: one child profile free, more with premium (subscriptions ADR-0001).
 * Rules cannot count, so the count is here, in the same transaction as the
 * write and the entitlement it is checked against (BE-06).
 *
 * Who may do it is who may edit the profile: an admin, or the person
 * themselves (family-profiles ADR-0001's `mayEditProfile`). Unmarking is
 * always allowed, and a household that has lost premium keeps every child it
 * already has — it only stops adding.
 */
export const setChildProfile = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(setChildProfileInput, request.data);
  await markChild(db(), uid, input, new Date());
  logger.info('child profile set', { householdId: input.householdId, isChild: input.isChild });
  return { isChild: input.isChild };
});

/** The body, apart from its transport, so the emulator suite drives it with a chosen `now`. */
export async function markChild(
  store: Firestore,
  uid: string,
  input: SetChildProfileInput,
  now: Date,
): Promise<void> {
  await store.runTransaction(async (transaction) => {
    const household = await readHousehold(transaction, store, input.householdId, () =>
      refuseSubscription('householdNotFound'),
    );
    const role = roleOf(household, uid);
    if (role === undefined) throw refuseSubscription('notAMember');
    const member = await transaction.get(memberRef(store, input.householdId, input.memberId));
    if (!member.exists) throw refuseSubscription('memberNotFound');
    if (role !== 'admin' && member.get('claimedBy') !== uid) throw refuseSubscription('notAnAdmin');

    const profiles = householdRef(store, input.householdId).collection(FAMILY_PROFILES);
    if (input.isChild) {
      const children = await transaction.get(
        profiles.where('isChild', '==', true).limit(FREE_CHILD_PROFILES + 1),
      );
      const others = children.docs.filter((doc) => doc.id !== input.memberId).length;
      const isPremium = await householdHasPremium(transaction, store, input.householdId, now);
      if (others >= FREE_CHILD_PROFILES && !isPremium) throw premiumRequired('additionalChild');
    }
    transaction.set(profiles.doc(input.memberId), { isChild: input.isChild }, { merge: true });
  });
}
