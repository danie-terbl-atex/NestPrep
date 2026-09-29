import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions/v2';

import { knownZoneOr } from '../calendar_sync/zoned_time';
import { MEMBERS, householdRef } from '../household/documents';
import {
  recipientsOf,
  storedHousehold,
  storedMember,
  type MemberRecord,
  type Recipient,
} from './recipients';

/**
 * A household as notifications needs it: its clock, its people's names, and
 * who among them can be told something (notifications ADR-0001). Read fresh
 * for every delivery, so somebody who left an hour ago is not buzzed.
 */
export interface HouseholdRoster {
  readonly householdId: string;
  readonly zone: string;
  readonly names: Readonly<Record<string, string>>;
  readonly recipients: readonly Recipient[];
}

/** More profiles than any household holds; the read is bounded all the same (BE-08). */
export const MEMBER_LIMIT = 50;

export async function loadRoster(
  store: Firestore,
  householdId: string,
): Promise<HouseholdRoster | null> {
  const home = householdRef(store, householdId);
  const [snapshot, memberDocs] = await Promise.all([
    home.get(),
    home.collection(MEMBERS).limit(MEMBER_LIMIT).get(),
  ]);
  if (!snapshot.exists) return null;
  const household = storedHousehold.safeParse(snapshot.data());
  if (!household.success) {
    logger.warn('notifications: a household did not parse', { householdId });
    return null;
  }
  const members: MemberRecord[] = memberDocs.docs.flatMap((doc) => {
    const member = storedMember.safeParse(doc.data());
    return member.success ? [{ ...member.data, id: doc.id }] : [];
  });
  return {
    householdId,
    zone: knownZoneOr(household.data.timeZone),
    names: Object.fromEntries(members.map((member) => [member.id, member.displayName])),
    recipients: recipientsOf(household.data, members),
  };
}

export function recipientIn(roster: HouseholdRoster, memberId: string): Recipient | undefined {
  return roster.recipients.find((recipient) => recipient.memberId === memberId);
}
