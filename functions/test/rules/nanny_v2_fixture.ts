import { Timestamp, doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

import { ROLE_DEFAULTS } from '../../src/household/access';
import { HOME, PEOPLE } from './access_fixture';
import { CARER, givenAHubOfEveryRole } from './nanny_fixture';
import { givenData, type Firestore } from './rules_harness';

/**
 * The nanny hub's V2 records (nanny-hub ADR-0004 to ADR-0006), on top of the
 * household of every role: a second carer, bookings at every distance from
 * now, and helpers to mark a carer shift-only and hand them a pass.
 *
 * Times are relative to the wall clock, because the rules compare them with
 * `request.time`; every window is far enough from its edge that a slow test
 * cannot cross it.
 */
export const OTHER_CARER = { uid: 'uid-zanele', member: 'm-zanele', role: 'carer' } as const;

export const V2_PATHS = {
  bookings: `${HOME}/nannyBookings`,
  passes: `${HOME}/nannyShiftPasses`,
  secret: `${HOME}/nannySecrets/alarm`,
  person: `${HOME}/nannyPickupPeople/gogo`,
  run: `${HOME}/nannySchoolRuns/${PEOPLE.kid.member}_1`,
  change: `${HOME}/nannyPickupChanges/${PEOPLE.kid.member}_2026-10-02`,
} as const;

const MINUTE = 60_000;

/** A moment [minutes] from now — negative is in the past. */
export function minutesFromNow(minutes: number): Timestamp {
  return Timestamp.fromMillis(Date.now() + minutes * MINUTE);
}

export function booking(
  carerMemberId: string,
  startsInMinutes: number,
  endsInMinutes: number,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    carerMemberId,
    startsAt: minutesFromNow(startsInMinutes),
    endsAt: minutesFromNow(endsInMinutes),
    note: null,
    createdBy: PEOPLE.admin.member,
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

export function secret(
  createdBy: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    label: 'Alarm',
    value: '4821',
    note: null,
    createdBy,
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

/** The hub, a second carer, and the alarm code. */
export async function givenAHubWithTwoCarers(): Promise<void> {
  await givenAHubOfEveryRole();
  await givenData(async (db: Firestore) => {
    await updateDoc(doc(db, HOME), {
      [`members.${OTHER_CARER.uid}`]: 'carer',
      [`profiles.${OTHER_CARER.uid}`]: OTHER_CARER.member,
      [`access.${OTHER_CARER.uid}`]: ROLE_DEFAULTS.carer,
    });
    await setDoc(doc(db, `${HOME}/members/${OTHER_CARER.member}`), {
      displayName: 'Zanele',
      color: 'mint',
      role: 'carer',
      claimedBy: OTHER_CARER.uid,
      access: ROLE_DEFAULTS.carer,
    });
    await setDoc(doc(db, V2_PATHS.secret), {
      ...secret(PEOPLE.admin.member),
      createdAt: new Date(),
    });
  });
}

/** What `setCarerShiftOnly` writes. */
export async function givenShiftOnly(memberId: string = CARER.member): Promise<void> {
  await givenData(async (db) => {
    await updateDoc(doc(db, HOME), { [`shiftOnly.${memberId}`]: true });
  });
}

/**
 * A booking for [carerMemberId], and the pass [passHolder] would write naming
 * it — the pass seeded with the rules off, so a test can hand a carer a pass
 * the rules would never have let them write.
 */
export async function givenABookingAndPass(options: {
  bookingId: string;
  carerMemberId: string;
  startsInMinutes: number;
  endsInMinutes: number;
  passHolder?: string;
}): Promise<void> {
  const startsAt = minutesFromNow(options.startsInMinutes);
  const endsAt = minutesFromNow(options.endsInMinutes);
  await givenData(async (db) => {
    await setDoc(doc(db, `${V2_PATHS.bookings}/${options.bookingId}`), {
      ...booking(options.carerMemberId, 0, 0, { startsAt, endsAt }),
      createdAt: new Date(),
    });
    const holder = options.passHolder ?? options.carerMemberId;
    await setDoc(doc(db, `${V2_PATHS.passes}/${holder}`), {
      bookingId: options.bookingId,
      startsAt,
      endsAt,
      updatedAt: new Date(),
    });
  });
}
