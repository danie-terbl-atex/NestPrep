import type { Role } from '../household/documents';

/**
 * What deleting an account does to one household it belongs to (accounts
 * ADR-0006):
 *
 * - `leave` — somebody else can still run the household, so the account
 *   simply goes, the way leaving does (household ADR-0001).
 * - `handOver` — the account is the last admin, and another *adult* in the
 *   family has joined: that adult becomes admin first, so the household is
 *   never left with nobody who can administer it (household ADR-0002).
 * - `end` — the account is the last admin and no other adult has joined.
 *   Helpers, carers and kids cannot run a family's household, so it ends,
 *   with everything in it; the preview names who loses access first.
 */
export type HouseholdOutcome =
  | { readonly kind: 'leave' }
  | { readonly kind: 'handOver'; readonly toUid: string; readonly toMemberId: string }
  | { readonly kind: 'end' };

/** Another account's claimed profile, as a candidate to run the household. */
export interface ClaimedAdult {
  readonly uid: string;
  readonly memberId: string;
  readonly role: Role;
  /** When the profile was made, so the choice is stable and the longest-standing wins. */
  readonly createdAtMillis: number;
}

/** A family adult: `parent`, and ADR-0001's `member`, read as parent (household ADR-0003). */
const ADULT_ROLES: readonly Role[] = ['admin', 'parent', 'member'];

export function decideOutcome(
  callerUid: string,
  roles: Readonly<Record<string, Role>>,
  others: readonly ClaimedAdult[],
): HouseholdOutcome {
  if (roles[callerUid] !== 'admin') return { kind: 'leave' };
  const otherAdmins = Object.entries(roles).filter(
    ([uid, role]) => uid !== callerUid && role === 'admin',
  );
  if (otherAdmins.length > 0) return { kind: 'leave' };

  const successor = others
    .filter((adult) => adult.uid !== callerUid && roles[adult.uid] === adult.role)
    .filter((adult) => ADULT_ROLES.includes(adult.role))
    .sort((a, b) => a.createdAtMillis - b.createdAtMillis || a.uid.localeCompare(b.uid))[0];
  if (successor === undefined) return { kind: 'end' };
  return { kind: 'handOver', toUid: successor.uid, toMemberId: successor.memberId };
}

/**
 * Whether the households the person agreed to end are exactly the ones that
 * would end now. Anything else — one more, one fewer — means the preview they
 * read is out of date, and nothing is deleted until they read it again.
 */
export function endingsAgree(agreed: readonly string[], planned: readonly string[]): boolean {
  const left = [...new Set(agreed)].sort();
  const right = [...new Set(planned)].sort();
  return left.length === right.length && left.every((id, index) => id === right[index]);
}
