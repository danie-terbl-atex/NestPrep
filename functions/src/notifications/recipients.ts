import { z } from 'zod';

import {
  AREAS,
  isFamilyRole,
  memberLevelIn,
  readGrant,
  type Area,
  type Level,
} from '../household/access';

/**
 * Who in a household can be told something, and what each of them may see
 * (notifications ADR-0001, household ADR-0003). Pure over the household and
 * member documents, so every "may a helper hear about this" is tested without
 * an emulator.
 *
 * A recipient is a member profile with at least one account or kid device
 * signed in as it — an unclaimed profile has nobody to buzz and nobody to read
 * its inbox. Levels are the same ones the rules read: a claimed member's from
 * the household's `access` map, a kid device's from its kid profile's own
 * `access`, and only while that profile is still a kid (accounts ADR-0004).
 */

export interface Recipient {
  readonly memberId: string;
  readonly displayName: string;
  readonly role: string;
  readonly isFamily: boolean;
  readonly levels: Readonly<Record<Area, Level>>;
  /** Every account and kid device signed in as this profile. */
  readonly uids: readonly string[];
  /** Whether a person claimed it with their own login, not only a kid device. */
  readonly hasAccount: boolean;
}

export const storedHousehold = z.object({
  timeZone: z.string().default('UTC'),
  members: z.record(z.string(), z.string()).default({}),
  access: z.record(z.string(), z.unknown()).optional(),
  kids: z.record(z.string(), z.string()).optional(),
  shiftOnly: z.record(z.string(), z.unknown()).optional(),
});
export type StoredHousehold = z.infer<typeof storedHousehold>;

export const storedMember = z.object({
  displayName: z.string().default(''),
  role: z.string().default('parent'),
  claimedBy: z.string().nullable().default(null),
  access: z.unknown().optional(),
});
export type StoredMember = z.infer<typeof storedMember>;

export interface MemberRecord extends StoredMember {
  readonly id: string;
}

function levelsFor(level: (area: Area) => Level): Record<Area, Level> {
  return Object.fromEntries(AREAS.map((area) => [area, level(area)])) as Record<Area, Level>;
}

function kidDeviceLevels(member: MemberRecord): Record<Area, Level> {
  const grant = member.role === 'kid' ? readGrant(member.access) : null;
  return levelsFor((area) => grant?.[area] ?? 'none');
}

export function recipientOf(household: StoredHousehold, member: MemberRecord): Recipient | null {
  const claimed =
    member.claimedBy !== null && member.claimedBy in household.members ? member.claimedBy : null;
  const kidDevices = Object.entries(household.kids ?? {})
    .filter(([, memberId]) => memberId === member.id)
    .map(([uid]) => uid);
  const uids = [...(claimed === null ? [] : [claimed]), ...kidDevices];
  if (uids.length === 0) return null;

  if (claimed !== null) {
    const role = household.members[claimed] ?? member.role;
    const grant = household.access?.[claimed];
    // A shift-only carer (nanny-hub ADR-0006) is told nothing about the
    // household: a digest or a push is read later, off shift, and would carry
    // what the rules keep from them then.
    const shiftOnly = household.shiftOnly?.[member.id] === true;
    return {
      memberId: member.id,
      displayName: member.displayName,
      role,
      isFamily: isFamilyRole(role),
      levels: levelsFor((area) => (shiftOnly ? 'none' : memberLevelIn(role, grant, area))),
      uids,
      hasAccount: true,
    };
  }
  return {
    memberId: member.id,
    displayName: member.displayName,
    role: member.role,
    isFamily: false,
    levels: kidDeviceLevels(member),
    uids,
    hasAccount: false,
  };
}

export function recipientsOf(
  household: StoredHousehold,
  members: readonly MemberRecord[],
): Recipient[] {
  return members.flatMap((member) => {
    const recipient = recipientOf(household, member);
    return recipient === null ? [] : [recipient];
  });
}

export function canSee(recipient: Recipient, area: Area): boolean {
  const level = recipient.levels[area];
  return level === 'view' || level === 'edit';
}

/** `own` or better — for areas where a person's own things are theirs to see. */
export function seesOwn(recipient: Recipient, area: Area): boolean {
  return recipient.levels[area] !== 'none';
}
