import type {
  DocumentData,
  DocumentReference,
  Firestore,
  Transaction,
} from 'firebase-admin/firestore';

/** The three roles a member can hold (household ADR-0001). */
export const ROLES = ['admin', 'member', 'helper'] as const;
export type Role = (typeof ROLES)[number];

export const HOUSEHOLDS = 'households';
export const MEMBERS = 'members';
export const INVITES = 'invites';
export const USERS = 'users';

/**
 * The household document's uid→role map: the one lookup every Security Rule
 * performs, and the reason membership is written only here (foundation
 * ADR-0002).
 */
export interface HouseholdDocument extends DocumentData {
  readonly name: string;
  readonly timeZone: string;
  readonly members: Record<string, Role>;
}

export interface MemberDocument extends DocumentData {
  readonly displayName: string;
  readonly color: string;
  readonly role: Role;
  readonly claimedBy: string | null;
}

export interface InviteDocument extends DocumentData {
  readonly householdId: string;
  readonly memberId: string;
  readonly redeemedBy: string | null;
}

export function householdRef(store: Firestore, householdId: string): DocumentReference {
  return store.collection(HOUSEHOLDS).doc(householdId);
}

export function memberRef(
  store: Firestore,
  householdId: string,
  memberId: string,
): DocumentReference {
  return householdRef(store, householdId).collection(MEMBERS).doc(memberId);
}

export function inviteRef(store: Firestore, code: string): DocumentReference {
  return store.collection(INVITES).doc(code);
}

export function userRef(store: Firestore, uid: string): DocumentReference {
  return store.collection(USERS).doc(uid);
}

/** Reads a household inside a transaction, or throws the caller's own error. */
export async function readHousehold(
  transaction: Transaction,
  store: Firestore,
  householdId: string,
  onMissing: () => Error,
): Promise<HouseholdDocument> {
  const snapshot = await transaction.get(householdRef(store, householdId));
  const data = snapshot.data() as HouseholdDocument | undefined;
  if (!snapshot.exists || data === undefined) throw onMissing();
  return data;
}

export function roleOf(household: HouseholdDocument, uid: string): Role | undefined {
  return household.members[uid];
}

export function adminCount(household: HouseholdDocument): number {
  return Object.values(household.members).filter((role) => role === 'admin').length;
}
