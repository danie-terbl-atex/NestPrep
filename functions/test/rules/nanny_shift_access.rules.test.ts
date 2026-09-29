import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { HOME, HOUSEHOLD, KID_DEVICE, PEOPLE, RECORDS } from './access_fixture';
import { CARER, CHILD, PATHS, shift } from './nanny_fixture';
import {
  OTHER_CARER,
  V2_PATHS,
  booking,
  givenABookingAndPass,
  givenAHubWithTwoCarers,
  givenShiftOnly,
  minutesFromNow,
  secret,
} from './nanny_v2_fixture';
import {
  asKid,
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
} from './rules_harness';

/**
 * Shift-only access (nanny-hub ADR-0006): parents book a carer's shifts
 * ahead; the carer names the booking they are on in a pass; the house codes
 * are read by anybody but family only inside a booked window of their own,
 * 15 minutes either side; and a carer marked shift-only sees nothing of the
 * household outside one.
 */

beforeEach(async () => {
  await clearData();
  await givenAHubWithTwoCarers();
});

const bookingPath = (id: string): string => `${HOME}/nannyBookings/${id}`;
const passPath = (memberId: string): string => `${HOME}/nannyShiftPasses/${memberId}`;

describe('booking a shift', () => {
  it('lets family book a carer ahead', async () => {
    for (const person of ['admin', 'parent'] as const) {
      const db = await asUser(PEOPLE[person].uid);
      await assertSucceeds(
        setDoc(
          doc(db, bookingPath(`by-${person}`)),
          booking(CARER.member, 60, 300, { createdBy: PEOPLE[person].member }),
        ),
      );
    }
  });

  it('refuses a carer booking themselves, and a helper at view', async () => {
    const carer = await asUser(CARER.uid);
    await assertFails(
      setDoc(
        doc(carer, bookingPath('mine')),
        booking(CARER.member, 60, 300, { createdBy: CARER.member }),
      ),
    );
    const viewer = await asUser(PEOPLE.viewer.uid);
    await assertFails(
      setDoc(
        doc(viewer, bookingPath('theirs')),
        booking(CARER.member, 60, 300, { createdBy: PEOPLE.viewer.member }),
      ),
    );
  });

  it('refuses a booking already over, longer than a day, or ending before it starts', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    const path = doc(db, bookingPath('bad'));
    await assertFails(setDoc(path, booking(CARER.member, -300, -10)));
    await assertFails(setDoc(path, booking(CARER.member, 60, 60 + 24 * 60 + 1)));
    await assertFails(setDoc(path, booking(CARER.member, 300, 60)));
    await assertFails(setDoc(path, booking(CARER.member, 60, 60)));
    await assertSucceeds(setDoc(path, booking(CARER.member, 60, 60 + 24 * 60)));
  });

  it('refuses a booking for nobody, in somebody else’s name, stamped by the client, or with more in it', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    const path = doc(db, bookingPath('bad'));
    await assertFails(setDoc(path, booking('m-nobody', 60, 300)));
    await assertFails(
      setDoc(path, booking(CARER.member, 60, 300, { createdBy: PEOPLE.parent.member })),
    );
    await assertFails(setDoc(path, booking(CARER.member, 60, 300, { createdAt: new Date() })));
    await assertFails(setDoc(path, booking(CARER.member, 60, 300, { status: 'open' })));
    await assertFails(setDoc(path, booking(CARER.member, 60, 300, { note: 'x'.repeat(201) })));
  });

  it('never changes a booking — moving one is cancelling and booking again', async () => {
    await givenABookingAndPass({
      bookingId: 'tonight',
      carerMemberId: CARER.member,
      startsInMinutes: 60,
      endsInMinutes: 300,
    });
    const db = await asUser(PEOPLE.admin.uid);
    await assertFails(updateDoc(doc(db, bookingPath('tonight')), { endsAt: minutesFromNow(400) }));
  });

  it('lets family cancel a booking and its pass in one go; a carer cancels nothing', async () => {
    await givenABookingAndPass({
      bookingId: 'tonight',
      carerMemberId: CARER.member,
      startsInMinutes: 60,
      endsInMinutes: 300,
    });
    const carer = await asUser(CARER.uid);
    await assertFails(deleteDoc(doc(carer, bookingPath('tonight'))));
    const parent = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(deleteDoc(doc(parent, bookingPath('tonight'))));
    await assertSucceeds(deleteDoc(doc(parent, passPath(CARER.member))));
  });
});

describe('reading bookings', () => {
  beforeEach(async () => {
    await givenABookingAndPass({
      bookingId: 'nomsa-friday',
      carerMemberId: CARER.member,
      startsInMinutes: 120,
      endsInMinutes: 300,
    });
    await givenABookingAndPass({
      bookingId: 'zanele-friday',
      carerMemberId: OTHER_CARER.member,
      startsInMinutes: 120,
      endsInMinutes: 300,
    });
  });

  it('lets family and anybody who reads the hub see every booking', async () => {
    for (const uid of [PEOPLE.admin.uid, PEOPLE.parent.uid, CARER.uid, PEOPLE.viewer.uid]) {
      const db = await asUser(uid);
      await assertSucceeds(getDocs(collection(db, V2_PATHS.bookings)));
    }
  });

  it('lets a shift-only carer off shift see their own bookings, and nobody else’s', async () => {
    await givenShiftOnly(CARER.member);
    const db = await asUser(CARER.uid);
    await assertSucceeds(getDoc(doc(db, bookingPath('nomsa-friday'))));
    await assertSucceeds(
      getDocs(query(collection(db, V2_PATHS.bookings), where('carerMemberId', '==', CARER.member))),
    );
    await assertFails(getDoc(doc(db, bookingPath('zanele-friday'))));
    await assertFails(getDocs(collection(db, V2_PATHS.bookings)));
  });

  it('refuses the cleaner, the kid’s tablet, a stranger and somebody signed out', async () => {
    const tablet = await asKid(KID_DEVICE, { householdId: HOUSEHOLD, memberId: CHILD });
    for (const db of [
      await asUser(PEOPLE.cleaner.uid),
      tablet,
      await asUser('uid-stranger'),
      await asSignedOut(),
    ]) {
      await assertFails(getDoc(doc(db, bookingPath('nomsa-friday'))));
    }
  });
});

describe('a carer’s pass', () => {
  beforeEach(async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, bookingPath('nomsa-friday')), {
        ...booking(CARER.member, 120, 300),
        createdAt: new Date(),
      });
      await setDoc(doc(db, bookingPath('zanele-friday')), {
        ...booking(OTHER_CARER.member, 120, 300),
        createdAt: new Date(),
      });
    });
  });

  async function passFor(
    bookingId: string,
    overrides: Record<string, unknown> = {},
  ): Promise<Record<string, unknown>> {
    const admin = await asUser(PEOPLE.admin.uid);
    const stored = (await getDoc(doc(admin, bookingPath(bookingId)))).data() ?? {};
    return {
      bookingId,
      startsAt: stored['startsAt'],
      endsAt: stored['endsAt'],
      updatedAt: serverTimestamp(),
      ...overrides,
    };
  }

  it('lets a carer name their own booking — even a shift-only carer off shift', async () => {
    await givenShiftOnly(CARER.member);
    const db = await asUser(CARER.uid);
    await assertSucceeds(setDoc(doc(db, passPath(CARER.member)), await passFor('nomsa-friday')));
  });

  it('refuses a pass naming somebody else’s booking, or one that is not there', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(setDoc(doc(db, passPath(CARER.member)), await passFor('zanele-friday')));
    await assertFails(
      setDoc(doc(db, passPath(CARER.member)), {
        ...(await passFor('nomsa-friday')),
        bookingId: 'nope',
      }),
    );
  });

  it('refuses times that are not the booking’s own', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(
      setDoc(
        doc(db, passPath(CARER.member)),
        await passFor('nomsa-friday', { endsAt: minutesFromNow(24 * 60) }),
      ),
    );
    await assertFails(
      setDoc(
        doc(db, passPath(CARER.member)),
        await passFor('nomsa-friday', { startsAt: minutesFromNow(-60) }),
      ),
    );
    await assertFails(
      setDoc(
        doc(db, passPath(CARER.member)),
        await passFor('nomsa-friday', { updatedAt: new Date() }),
      ),
    );
  });

  it('refuses writing somebody else’s pass — another carer’s, or family’s for a carer', async () => {
    const zanele = await asUser(OTHER_CARER.uid);
    await assertFails(setDoc(doc(zanele, passPath(CARER.member)), await passFor('nomsa-friday')));
    const admin = await asUser(PEOPLE.admin.uid);
    await assertFails(setDoc(doc(admin, passPath(CARER.member)), await passFor('nomsa-friday')));
  });

  it('lets family and the carer read and delete it; another carer neither', async () => {
    await givenABookingAndPass({
      bookingId: 'nomsa-friday',
      carerMemberId: CARER.member,
      startsInMinutes: 120,
      endsInMinutes: 300,
    });
    const zanele = await asUser(OTHER_CARER.uid);
    await assertFails(getDoc(doc(zanele, passPath(CARER.member))));
    await assertFails(deleteDoc(doc(zanele, passPath(CARER.member))));
    const nomsa = await asUser(CARER.uid);
    await assertSucceeds(getDoc(doc(nomsa, passPath(CARER.member))));
    const admin = await asUser(PEOPLE.admin.uid);
    await assertSucceeds(getDoc(doc(admin, passPath(CARER.member))));
    await assertSucceeds(deleteDoc(doc(admin, passPath(CARER.member))));
  });
});

describe('the house codes, by the clock', () => {
  const readSecret = async (uid: string): Promise<unknown> =>
    getDoc(doc(await asUser(uid), V2_PATHS.secret));

  const nomsaBooked = (startsInMinutes: number, endsInMinutes: number): Promise<void> =>
    givenABookingAndPass({
      bookingId: 'nomsa-shift',
      carerMemberId: CARER.member,
      startsInMinutes,
      endsInMinutes,
    });

  it('lets family read them at any time, with no booking at all', async () => {
    for (const person of ['admin', 'parent', 'legacyMember'] as const) {
      await assertSucceeds(readSecret(PEOPLE[person].uid));
    }
  });

  it('refuses the carer before the window opens — two hours before the shift', async () => {
    await nomsaBooked(120, 300);
    await assertFails(readSecret(CARER.uid));
  });

  it('refuses the carer 20 minutes before the shift, outside the grace', async () => {
    await nomsaBooked(20, 300);
    await assertFails(readSecret(CARER.uid));
  });

  it('lets the carer in 10 minutes before the shift starts, inside the grace', async () => {
    await nomsaBooked(10, 300);
    await assertSucceeds(readSecret(CARER.uid));
  });

  it('lets the carer read them during the shift, one by one and as a list', async () => {
    await nomsaBooked(-60, 60);
    await assertSucceeds(readSecret(CARER.uid));
    const db = await asUser(CARER.uid);
    await assertSucceeds(getDocs(collection(db, `${HOME}/nannySecrets`)));
  });

  it('lets the carer in 10 minutes after the shift ended, inside the grace', async () => {
    await nomsaBooked(-300, -10);
    await assertSucceeds(readSecret(CARER.uid));
  });

  it('refuses the carer 20 minutes after the shift ended, outside the grace', async () => {
    await nomsaBooked(-300, -20);
    await assertFails(readSecret(CARER.uid));
  });

  it('refuses the carer after the shift — ended two hours ago', async () => {
    await nomsaBooked(-300, -120);
    await assertFails(readSecret(CARER.uid));
  });

  it('refuses another carer whose pass names the first carer’s booking', async () => {
    await givenABookingAndPass({
      bookingId: 'nomsa-shift',
      carerMemberId: CARER.member,
      startsInMinutes: -60,
      endsInMinutes: 60,
      passHolder: OTHER_CARER.member,
    });
    await assertFails(readSecret(OTHER_CARER.uid));
  });

  it('refuses a carer who is booked now but never named the booking', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, bookingPath('unnamed')), {
        ...booking(CARER.member, -60, 60),
        createdAt: new Date(),
      });
    });
    await assertFails(readSecret(CARER.uid));
  });

  it('lets a helper who reads the hub in only on a shift booked for them', async () => {
    await assertFails(readSecret(PEOPLE.viewer.uid));
    await givenABookingAndPass({
      bookingId: 'vera-shift',
      carerMemberId: PEOPLE.viewer.member,
      startsInMinutes: -60,
      endsInMinutes: 60,
    });
    await assertSucceeds(readSecret(PEOPLE.viewer.uid));
  });

  it('refuses whoever the hub is closed to, booked or not, and strangers', async () => {
    await givenABookingAndPass({
      bookingId: 'thandi-shift',
      carerMemberId: PEOPLE.cleaner.member,
      startsInMinutes: -60,
      endsInMinutes: 60,
    });
    await assertFails(readSecret(PEOPLE.cleaner.uid));
    await assertFails(readSecret(PEOPLE.kid.uid));
    const tablet = await asKid(KID_DEVICE, { householdId: HOUSEHOLD, memberId: CHILD });
    await assertFails(getDoc(doc(tablet, V2_PATHS.secret)));
    await assertFails(readSecret('uid-stranger'));
    await assertFails(getDoc(doc(await asSignedOut(), V2_PATHS.secret)));
  });

  it('never lets a carer write them, even on shift', async () => {
    await nomsaBooked(-60, 60);
    const db = await asUser(CARER.uid);
    await assertFails(setDoc(doc(db, `${HOME}/nannySecrets/gate`), secret(CARER.member)));
    await assertFails(updateDoc(doc(db, V2_PATHS.secret), { value: '0000' }));
    await assertFails(deleteDoc(doc(db, V2_PATHS.secret)));
  });

  it('lets family add, change and remove them', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(
      setDoc(doc(db, `${HOME}/nannySecrets/gate`), secret(PEOPLE.parent.member, { label: 'Gate' })),
    );
    await assertSucceeds(updateDoc(doc(db, V2_PATHS.secret), { value: '9999', note: 'Hold 3s' }));
    await assertSucceeds(deleteDoc(doc(db, V2_PATHS.secret)));
  });

  it('refuses a code that is blank, too long, in somebody else’s name or carrying more', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    const gate = doc(db, `${HOME}/nannySecrets/gate`);
    const by = PEOPLE.parent.member;
    await assertFails(setDoc(gate, secret(by, { label: '' })));
    await assertFails(setDoc(gate, secret(by, { value: 'x'.repeat(121) })));
    await assertFails(setDoc(gate, secret(by, { note: 'x'.repeat(201) })));
    await assertFails(setDoc(gate, secret(PEOPLE.admin.member)));
    await assertFails(setDoc(gate, secret(by, { createdAt: new Date() })));
    await assertFails(setDoc(gate, secret(by, { hint: 'the dog’s name' })));
    await assertFails(updateDoc(doc(db, V2_PATHS.secret), { createdBy: by }));
  });
});

describe('a shift-only carer and the rest of the household', () => {
  const readsContacts = async (uid: string): Promise<unknown> =>
    getDoc(doc(await asUser(uid), PATHS.contact));
  const readsGroceries = async (uid: string): Promise<unknown> =>
    getDoc(doc(await asUser(uid), RECORDS.groceries[0]));

  it('sees nothing of the household before their shift', async () => {
    await givenShiftOnly(CARER.member);
    await givenABookingAndPass({
      bookingId: 'later',
      carerMemberId: CARER.member,
      startsInMinutes: 120,
      endsInMinutes: 300,
    });
    await assertFails(readsContacts(CARER.uid));
    await assertFails(readsGroceries(CARER.uid));
    const db = await asUser(CARER.uid);
    await assertFails(setDoc(doc(db, `${HOME}/nannyShifts/early`), shift(CARER.member)));
  });

  it('sees what their grant opens during it, and may start the shift', async () => {
    await givenShiftOnly(CARER.member);
    await givenABookingAndPass({
      bookingId: 'now',
      carerMemberId: CARER.member,
      startsInMinutes: -60,
      endsInMinutes: 60,
    });
    await assertSucceeds(readsContacts(CARER.uid));
    await assertSucceeds(readsGroceries(CARER.uid));
    const db = await asUser(CARER.uid);
    await assertSucceeds(setDoc(doc(db, `${HOME}/nannyShifts/now`), shift(CARER.member)));
  });

  it('sees nothing again after it', async () => {
    await givenShiftOnly(CARER.member);
    await givenABookingAndPass({
      bookingId: 'earlier',
      carerMemberId: CARER.member,
      startsInMinutes: -300,
      endsInMinutes: -120,
    });
    await assertFails(readsContacts(CARER.uid));
    await assertFails(readsGroceries(CARER.uid));
  });

  it('sees nothing with a pass naming another carer’s booking that is on now', async () => {
    await givenShiftOnly(CARER.member);
    await givenABookingAndPass({
      bookingId: 'zanele-now',
      carerMemberId: OTHER_CARER.member,
      startsInMinutes: -60,
      endsInMinutes: 60,
      passHolder: CARER.member,
    });
    await assertFails(readsContacts(CARER.uid));
  });

  it('still reads the household and its people, so the app can say when the shift is', async () => {
    await givenShiftOnly(CARER.member);
    const db = await asUser(CARER.uid);
    await assertSucceeds(getDoc(doc(db, HOME)));
    await assertSucceeds(getDocs(collection(db, `${HOME}/members`)));
  });

  it('leaves a carer who is not shift-only reading at any time', async () => {
    await givenShiftOnly(OTHER_CARER.member);
    await assertSucceeds(readsContacts(CARER.uid));
    await assertSucceeds(readsGroceries(CARER.uid));
    await assertFails(readsContacts(OTHER_CARER.uid));
  });

  it('never narrows family, even marked', async () => {
    await givenShiftOnly(PEOPLE.admin.member);
    await assertSucceeds(readsContacts(PEOPLE.admin.uid));
    await assertSucceeds(readsGroceries(PEOPLE.admin.uid));
  });

  it('cannot be written by a client — only `setCarerShiftOnly` marks anybody', async () => {
    const admin = await asUser(PEOPLE.admin.uid);
    await assertFails(updateDoc(doc(admin, HOME), { [`shiftOnly.${CARER.member}`]: true }));
    await givenShiftOnly(CARER.member);
    const carer = await asUser(CARER.uid);
    await assertFails(updateDoc(doc(carer, HOME), { shiftOnly: {} }));
  });
});
