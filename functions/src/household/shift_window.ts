import { type Firestore, Timestamp } from 'firebase-admin/firestore';
import { z } from 'zod';

import { type Level, memberLevelIn, type Area } from './access';
import { HOUSEHOLDS } from './documents';

/**
 * Shift-only carers on the server (nanny-hub ADR-0006) — the Functions' copy
 * of `rules/firestore/shared/shift_window.rules`. A member a parent marked
 * shift-only (the household document's `shiftOnly` map, member id → true)
 * holds their grant only from 15 minutes before a shift booked for them to 15
 * minutes after it ends; outside every such window every area is `none`.
 *
 * The rules cannot query, so there the carer names their booking in a pass.
 * A Function can, so here the bookings themselves are asked — the same
 * windows, with nothing a client wrote in between. Every callable that
 * authorises by grant asks this after `memberLevelIn` (`levelNow`), or the
 * server would open to a carer what the rules keep shut.
 */

export const NANNY_BOOKINGS = 'nannyBookings';

/** The grace either side of a booked shift; `NannyLimits.shiftGrace` in the app. */
export const SHIFT_GRACE_MS = 15 * 60 * 1000;

/** Bookings a carer can hold that could be open now; more than any week has. */
const BOOKING_LOOKUP = 20;

const householdShape = z.object({
  profiles: z.record(z.string(), z.string()).optional(),
  shiftOnly: z.record(z.string(), z.unknown()).optional(),
});

const bookingShape = z.object({
  carerMemberId: z.string(),
  startsAt: z.instanceof(Timestamp),
  endsAt: z.instanceof(Timestamp),
});

/** The member id this account claimed, when a parent marked it shift-only. */
export function shiftOnlyMemberOf(householdData: unknown, uid: string): string | null {
  const household = householdShape.safeParse(householdData);
  if (!household.success) return null;
  const memberId = household.data.profiles?.[uid];
  if (memberId === undefined) return null;
  return household.data.shiftOnly?.[memberId] === true ? memberId : null;
}

/** Whether one booking's window, with the grace either side, holds [now]. */
export function isWithinWindow(startsAt: Date, endsAt: Date, now: Date): boolean {
  const at = now.getTime();
  return at >= startsAt.getTime() - SHIFT_GRACE_MS && at <= endsAt.getTime() + SHIFT_GRACE_MS;
}

/** Whether a shift booked for [memberId] is on at [now]. */
export async function isOnBookedShift(
  store: Firestore,
  householdId: string,
  memberId: string,
  now: Date,
): Promise<boolean> {
  const bookings = await store
    .collection(HOUSEHOLDS)
    .doc(householdId)
    .collection(NANNY_BOOKINGS)
    .where('carerMemberId', '==', memberId)
    .where('endsAt', '>=', Timestamp.fromMillis(now.getTime() - SHIFT_GRACE_MS))
    .orderBy('endsAt')
    .limit(BOOKING_LOOKUP)
    .get();
  return bookings.docs.some((doc) => {
    const booking = bookingShape.safeParse(doc.data());
    return (
      booking.success &&
      booking.data.carerMemberId === memberId &&
      isWithinWindow(booking.data.startsAt.toDate(), booking.data.endsAt.toDate(), now)
    );
  });
}

/** A shift-only member outside every booked window: they hold nothing now. */
export async function isOffShift(
  store: Firestore,
  householdId: string,
  householdData: unknown,
  uid: string,
  now: Date,
): Promise<boolean> {
  const memberId = shiftOnlyMemberOf(householdData, uid);
  if (memberId === null) return false;
  return !(await isOnBookedShift(store, householdId, memberId, now));
}

/**
 * [memberLevelIn], and `none` for a shift-only member off shift — the level
 * the rules' `levelIn` gives the same person at the same moment.
 */
export async function levelNow(
  store: Firestore,
  call: {
    householdId: string;
    householdData: unknown;
    uid: string;
    role: string;
    storedGrant: unknown;
    area: Area;
    now?: Date;
  },
): Promise<Level> {
  const level = memberLevelIn(call.role, call.storedGrant, call.area);
  if (level === 'none') return level;
  const off = await isOffShift(
    store,
    call.householdId,
    call.householdData,
    call.uid,
    call.now ?? new Date(),
  );
  return off ? 'none' : level;
}
