import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { householdRef, memberRef, readHousehold, roleOf } from '../household/documents';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { FREE_CHILD_PROFILES } from '../subscriptions/entitlement';
import { premiumRequired, refuseSubscription } from '../subscriptions/errors';
import { type SetChildProfileInput, setChildProfileInput } from '../subscriptions/schemas';
import { freeChildRef, householdHasPremium } from '../subscriptions/subscription_documents';
import { FAMILY_PROFILES } from './member_details';

/**
 * Marks a member as a child, or not — the one write to `familyProfiles` a
 * client may not make itself, because it is what the free tier is counted
 * by: one child profile free, more with premium (subscriptions ADR-0001).
 * Rules cannot count, so the count is here, in the same transaction as the
 * write and the entitlement it is checked against (BE-06).
 *
 * It also keeps which child the free tier plans for (lunch-box ADR-0009):
 * the first child marked, until they are unmarked, when another child — if
 * there is one — takes the place. A premium household plans for every child;
 * the record says which one stays planned if premium lapses.
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
    const children = await transaction.get(
      profiles.where('isChild', '==', true).limit(FREE_CHILD_PROFILES + 1),
    );
    const others = children.docs.filter((doc) => doc.id !== input.memberId).map((doc) => doc.id);
    const freeChild = await transaction.get(freeChildRef(store, input.householdId));
    const freeChildId = freeChildIdOf(freeChild.get('memberId'));
    // The query above stops at two, so the free child's own profile says
    // whether they are still a child — in a premium household with several.
    const freeChildIsAChild =
      freeChildId !== null &&
      freeChildId !== input.memberId &&
      (await transaction.get(profiles.doc(freeChildId))).get('isChild') === true;
    if (input.isChild) {
      const isPremium = await householdHasPremium(transaction, store, input.householdId, now);
      if (others.length >= FREE_CHILD_PROFILES && !isPremium) {
        throw premiumRequired('additionalChild');
      }
    }
    transaction.set(profiles.doc(input.memberId), { isChild: input.isChild }, { merge: true });
    const nextFreeChild = freeChildAfter({
      current: freeChildId,
      currentIsAChild: freeChildIsAChild,
      memberId: input.memberId,
      isChild: input.isChild,
      otherChildren: others,
    });
    if (nextFreeChild === freeChildId) return;
    if (nextFreeChild === null) transaction.delete(freeChildRef(store, input.householdId));
    else transaction.set(freeChildRef(store, input.householdId), { memberId: nextFreeChild });
  });
}

function freeChildIdOf(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}

/**
 * Which child the free tier plans for once this marking is written: whoever
 * it already was, while they are still a child; otherwise the child just
 * marked, or another child the household already has; otherwise nobody.
 */
export function freeChildAfter(marking: {
  current: string | null;
  currentIsAChild: boolean;
  memberId: string;
  isChild: boolean;
  otherChildren: readonly string[];
}): string | null {
  const { current, currentIsAChild, memberId, isChild, otherChildren } = marking;
  if (current !== null && current !== memberId && currentIsAChild) return current;
  if (current === memberId && isChild) return current;
  if (isChild) return otherChildren[0] ?? memberId;
  return otherChildren[0] ?? null;
}
