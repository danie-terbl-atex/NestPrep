import {
  FieldValue,
  type DocumentReference,
  type Firestore,
  type Transaction,
} from 'firebase-admin/firestore';

import {
  type MemberDocument,
  householdRef,
  memberRef,
  userRef,
  MEMBERS,
  HOUSEHOLDS,
} from './documents';

/**
 * The profile this account claimed in this household, or null when it claimed
 * none. Leaving and being removed both need it, which is why it is here rather
 * than in either (ENG-02).
 */
export async function findClaimedMember(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  uid: string,
): Promise<DocumentReference | null> {
  const matches = await transaction.get(
    store
      .collection(HOUSEHOLDS)
      .doc(householdId)
      .collection(MEMBERS)
      .where('claimedBy', '==', uid)
      .limit(1),
  );
  const first = matches.docs[0];
  return first === undefined ? null : first.ref;
}

/**
 * Detaches an account from a household everywhere it is recorded: the profile
 * becomes unclaimed, the household's uid→role map loses the uid, and the
 * account's household list loses the household. The profile itself stays, so
 * everything assigned to it still reads (household ADR-0001).
 *
 * Every write is staged on the caller's transaction, so leaving and being
 * removed are both atomic (BE-07).
 */
export function detachMember(
  transaction: Transaction,
  store: Firestore,
  options: { householdId: string; uid: string; claimedMember: DocumentReference | null },
): void {
  const { householdId, uid, claimedMember } = options;
  if (claimedMember !== null) {
    transaction.update(claimedMember, { claimedBy: null });
  }
  transaction.update(householdRef(store, householdId), {
    [`members.${uid}`]: FieldValue.delete(),
  });
  transaction.set(
    userRef(store, uid),
    {
      householdIds: FieldValue.arrayRemove(householdId),
      activeHouseholdId: null,
    },
    { merge: true },
  );
}

/** Reads a member profile inside a transaction. */
export async function readMember(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  memberId: string,
): Promise<MemberDocument | undefined> {
  const snapshot = await transaction.get(memberRef(store, householdId, memberId));
  return snapshot.data() as MemberDocument | undefined;
}
