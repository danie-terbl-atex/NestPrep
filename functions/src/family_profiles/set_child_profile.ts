import {
  FieldValue,
  type DocumentSnapshot,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';

import { householdRef, memberRef, readHousehold, roleOf } from '../household/documents';
import { findClaimedMember } from '../household/membership';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { refuseSubscription } from '../subscriptions/errors';
import { type SetChildProfileInput, setChildProfileInput } from '../subscriptions/schemas';
import { FAMILY_PROFILES } from './member_details';

/**
 * Marks a member as a child, or not — the one write to `familyProfiles` a
 * client may not make itself, because marking a child needs a parent's
 * consent written with it (accounts ADR-0005). A household marks as many
 * children as it has (subscriptions ADR-0008).
 *
 * Who may do it is who may edit the profile: an admin, or the person
 * themselves (family-profiles ADR-0001's `mayEditProfile`).
 *
 * The consent is one already on the member profile, or one given with this
 * call, which is written in the same transaction as the caller's own profile
 * having given it. It is never replaced once given.
 */
export const setChildProfile = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(setChildProfileInput, request.data);
  await markChild(db(), uid, input);
  logger.info('child profile set', { householdId: input.householdId, isChild: input.isChild });
  return { isChild: input.isChild };
});

/** The body, apart from its transport, so the emulator suite drives it directly. */
export async function markChild(
  store: Firestore,
  uid: string,
  input: SetChildProfileInput,
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
    const consentBy = await consentToRecord(transaction, store, { input, uid, member });

    const profiles = householdRef(store, input.householdId).collection(FAMILY_PROFILES);
    transaction.set(profiles.doc(input.memberId), { isChild: input.isChild }, { merge: true });
    if (consentBy !== null && input.guardianConsent !== undefined) {
      transaction.update(member.ref, {
        guardianConsent: {
          byMemberId: consentBy,
          version: input.guardianConsent.version,
          at: FieldValue.serverTimestamp(),
        },
      });
    }
  });
}

/**
 * Whose consent to write for this call, or null when none is to be written:
 * unmarking, or a member whose consent is on record already. Refuses a child
 * with none on record and none given (accounts ADR-0005). The consent is the
 * caller's own, as the profile they claimed — never a member id they name.
 */
async function consentToRecord(
  transaction: Transaction,
  store: Firestore,
  call: { input: SetChildProfileInput; uid: string; member: DocumentSnapshot },
): Promise<string | null> {
  const { input, uid, member } = call;
  if (!input.isChild || member.get('guardianConsent') != null) return null;
  if (input.guardianConsent === undefined) throw refuseSubscription('guardianConsentRequired');
  const own = await findClaimedMember(transaction, store, input.householdId, uid);
  if (own === null) throw refuseSubscription('notAMember');
  return own.id;
}
