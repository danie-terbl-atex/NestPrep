import { ROLE_DEFAULTS, uniformGrant, type Grant } from '../../../src/household/access';
import type { HouseholdDay } from '../../../src/notifications/digest_facts';
import type { HouseholdRoster } from '../../../src/notifications/household_roster';
import {
  recipientsOf,
  type MemberRecord,
  type Recipient,
  type StoredHousehold,
} from '../../../src/notifications/recipients';

/**
 * One household of every kind of person the digest has to get right: two
 * parents, two children (one on a kid tablet), a carer, a helper who only
 * cleans, and a granny nobody has claimed. Grants are built from the real
 * defaults, so a changed default is a changed assertion.
 */
export const CLEANING_ONLY: Grant = { ...uniformGrant('none'), homeCare: 'own' };

export const MEMBERS: MemberRecord[] = [
  { id: 'm-sam', displayName: 'Sam', role: 'admin', claimedBy: 'uid-sam', access: undefined },
  { id: 'm-pat', displayName: 'Pat', role: 'parent', claimedBy: 'uid-pat', access: undefined },
  { id: 'm-mia', displayName: 'Mia', role: 'kid', claimedBy: null, access: ROLE_DEFAULTS.kid },
  { id: 'm-leo', displayName: 'Leo', role: 'kid', claimedBy: null, access: ROLE_DEFAULTS.kid },
  {
    id: 'm-nomsa',
    displayName: 'Nomsa',
    role: 'carer',
    claimedBy: 'uid-nomsa',
    access: ROLE_DEFAULTS.carer,
  },
  {
    id: 'm-thandi',
    displayName: 'Thandi',
    role: 'helper',
    claimedBy: 'uid-thandi',
    access: CLEANING_ONLY,
  },
  { id: 'm-gogo', displayName: 'Gogo', role: 'parent', claimedBy: null, access: undefined },
];

export const HOUSEHOLD: StoredHousehold = {
  timeZone: 'Africa/Johannesburg',
  members: {
    'uid-sam': 'admin',
    'uid-pat': 'parent',
    'uid-nomsa': 'carer',
    'uid-thandi': 'helper',
  },
  access: { 'uid-nomsa': ROLE_DEFAULTS.carer, 'uid-thandi': CLEANING_ONLY },
  kids: { 'kid-tablet': 'm-mia' },
};

export const RECIPIENTS: Recipient[] = recipientsOf(HOUSEHOLD, MEMBERS);

export function person(memberId: string): Recipient {
  const found = RECIPIENTS.find((recipient) => recipient.memberId === memberId);
  if (found === undefined) throw new Error(`no recipient ${memberId}`);
  return found;
}

export const ROSTER: HouseholdRoster = {
  householdId: 'h-parkers',
  zone: 'Africa/Johannesburg',
  names: Object.fromEntries(MEMBERS.map((member) => [member.id, member.displayName])),
  recipients: RECIPIENTS,
};

/** A Tuesday with something in every section. */
export const TODAY = '2026-09-29';

export function aBusyDay(overrides: Partial<HouseholdDay> = {}): HouseholdDay {
  return {
    today: TODAY,
    zone: 'Africa/Johannesburg',
    names: ROSTER.names,
    events: [
      { title: 'Doctor for Leo', startMinute: null, memberIds: ['m-leo'] },
      { title: 'School run', startMinute: 7 * 60 + 15, memberIds: ['m-sam', 'm-mia'] },
      { title: 'Swimming lesson', startMinute: 15 * 60, memberIds: ['m-leo'] },
    ],
    lunchBoxes: [
      { childId: 'm-mia', items: ['Cheese sandwich', 'Apple'] },
      { childId: 'm-leo', items: ['Wrap', 'Carrots'] },
    ],
    chores: [
      { title: 'Make your bed', assigneeIds: ['m-mia'] },
      { title: 'Bins out', assigneeIds: ['m-sam'] },
      { title: 'Water the plants', assigneeIds: [] },
    ],
    documents: [{ name: 'Leo passport', expiresOn: '2026-10-11' }],
    vaults: { 'm-sam': [{ name: 'Sam ID', expiresOn: '2026-10-01' }] },
    openShifts: [{ carerMemberId: 'm-nomsa', startedAt: new Date('2026-09-29T05:10:00Z') }],
    handovers: [{ carerMemberId: 'm-nomsa', entryCount: 6 }],
    choresToCheck: 2,
    rewardsAskedFor: 1,
    ...overrides,
  };
}

export const AN_EMPTY_DAY: HouseholdDay = aBusyDay({
  events: [],
  lunchBoxes: [],
  chores: [],
  documents: [],
  vaults: {},
  openShifts: [],
  handovers: [],
  choresToCheck: 0,
  rewardsAskedFor: 0,
});
