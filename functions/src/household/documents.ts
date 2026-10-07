import type {
  DocumentData,
  DocumentReference,
  Firestore,
  Transaction,
} from 'firebase-admin/firestore';

/**
 * The roles a member can be given (household ADR-0003). `member` is not among
 * them: it is ADR-0001's name for a family adult, still read as `parent` on
 * every profile that carries it, and never written again.
 */
export const ROLES = ['admin', 'parent', 'kid', 'helper', 'carer'] as const;
export type AssignableRole = (typeof ROLES)[number];
export type Role = AssignableRole | 'member';

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

  /**
   * Kid devices: uid → the member profile each is signed in as. Not members —
   * a separate map so no `isMember()` ever matches one (accounts ADR-0003).
   * Absent on every household that has never paired a device.
   */
  readonly kids?: Record<string, string>;

  /**
   * uid → area → level for every claimed member who is not family, and the
   * member id each uid claimed — what `canView`, `canEdit` and `own` read in
   * the rules (household ADR-0003). Absent on households made before it.
   */
  readonly access?: Record<string, Record<string, string>>;
  readonly profiles?: Record<string, string>;
}

export interface MemberDocument extends DocumentData {
  readonly displayName: string;
  readonly color: string;
  readonly role: Role;
  readonly claimedBy: string | null;

  /**
   * `YYYY-MM-DD`, or `--MM-DD` where the household does not know the year, and
   * absent on every profile written before the field existed (birthdays
   * ADR-0001).
   *
   * No callable writes it: a profile's birthday is set by the client, under the
   * `members` rules. It is declared here because this interface is the home of
   * the stored member shape, and a stored field missing from it is how the next
   * callable to touch a member overwrites something it did not know was there.
   */
  readonly birthday?: string | null;

  /** What a parent chose for a kid, helper or carer (household ADR-0003). */
  readonly access?: Record<string, string> | null;
}

export interface InviteDocument extends DocumentData {
  readonly householdId: string;
  readonly memberId: string;
  readonly createdBy: string;
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
