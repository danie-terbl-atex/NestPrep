import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { HOME, PEOPLE } from './access_fixture';
import {
  CARER,
  CHILD,
  PATHS,
  card,
  contact,
  entry,
  givenNannyPremium,
  shift,
} from './nanny_fixture';
import {
  V2_PATHS,
  booking,
  givenABookingAndPass,
  givenAHubWithTwoCarers,
  givenShiftOnly,
  secret,
} from './nanny_v2_fixture';
import {
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * The nanny hub is Premium in full (subscriptions ADR-0008, ADR-0009): a
 * household without it adds and changes nothing in the hub, and still reads
 * and removes everything it made. A carer's pass is the one write left free,
 * because it is how a shift-only carer gets into the household at all.
 */

const ADMIN = PEOPLE.admin;
const SENT = `${PATHS.openShift}/photoUpdates/garden`;
const BOOKING = `${V2_PATHS.bookings}/saturday`;

const family = (): Promise<Firestore> => asUser(ADMIN.uid);
const carer = (): Promise<Firestore> => asUser(CARER.uid);

function photoUpdate(byMemberId: string): Record<string, unknown> {
  return {
    photoId: 'photo-garden-01',
    caption: 'Painting in the garden',
    childIds: [CHILD],
    byMemberId,
    createdAt: serverTimestamp(),
    delivery: { state: 'pending' },
  };
}

function pickupPerson(createdBy: string): Record<string, unknown> {
  return {
    name: 'Gogo Dlamini',
    relationship: 'Grandmother',
    idNote: null,
    phone: '+27 82 555 0100',
    photoId: null,
    childIds: [CHILD],
    createdBy,
    createdAt: serverTimestamp(),
  };
}

function schoolRun(updatedBy: string): Record<string, unknown> {
  return {
    childId: CHILD,
    weekday: 1,
    personId: 'gogo',
    memberId: null,
    atMinute: 870,
    place: 'Oakwood Primary gate',
    updatedBy,
    updatedAt: serverTimestamp(),
  };
}

function pickupChange(updatedBy: string): Record<string, unknown> {
  return {
    childId: CHILD,
    date: '2026-10-02',
    personId: null,
    memberId: CARER.member,
    atMinute: 780,
    note: 'Half day',
    updatedBy,
    updatedAt: serverTimestamp(),
  };
}

const stamped = (by: string): Record<string, unknown> => ({
  updatedBy: by,
  updatedAt: serverTimestamp(),
});

const PREMIUM_WRITES: readonly (readonly [string, () => Promise<unknown>])[] = [
  [
    'a new child card',
    async (): Promise<unknown> =>
      setDoc(
        doc(await family(), `${HOME}/nannyChildCards/${PEOPLE.parent.member}`),
        card(ADMIN.member),
      ),
  ],
  [
    'a changed child card',
    async (): Promise<unknown> => setDoc(doc(await carer(), PATHS.card), card(CARER.member)),
  ],
  [
    'a new contact',
    async (): Promise<unknown> =>
      setDoc(doc(await family(), `${HOME}/nannyContacts/new`), contact(ADMIN.member)),
  ],
  [
    'a changed contact',
    async (): Promise<unknown> =>
      updateDoc(doc(await carer(), PATHS.contact), { phone: '082 555 0199' }),
  ],
  [
    'the emergency sheet',
    async (): Promise<unknown> =>
      setDoc(doc(await family(), PATHS.sheet), {
        address: '14 Acacia Lane',
        ...stamped(ADMIN.member),
      }),
  ],
  [
    'a new place in the guide',
    async (): Promise<unknown> =>
      setDoc(doc(await carer(), `${HOME}/nannyGuide/new`), {
        title: 'First-aid kit',
        note: null,
        photoId: null,
        createdBy: CARER.member,
        createdAt: serverTimestamp(),
      }),
  ],
  [
    'a changed place in the guide',
    async (): Promise<unknown> =>
      updateDoc(doc(await carer(), PATHS.spot), { note: 'Bottom shelf' }),
  ],
  [
    'a new house rule',
    async (): Promise<unknown> =>
      setDoc(doc(await carer(), `${HOME}/nannyRules/new`), {
        text: 'Bed by eight',
        createdBy: CARER.member,
        createdAt: serverTimestamp(),
      }),
  ],
  [
    'a changed house rule',
    async (): Promise<unknown> =>
      updateDoc(doc(await carer(), PATHS.rule), { text: 'No screens after 5' }),
  ],
  [
    'a new checklist',
    async (): Promise<unknown> =>
      setDoc(doc(await family(), `${HOME}/nannyChecklists/arrival`), {
        items: [{ id: 'hands', text: 'Wash hands' }],
        ...stamped(ADMIN.member),
      }),
  ],
  [
    'a changed checklist',
    async (): Promise<unknown> =>
      setDoc(doc(await family(), PATHS.checklist), { items: [], ...stamped(ADMIN.member) }),
  ],
  [
    'a shift started',
    async (): Promise<unknown> =>
      setDoc(doc(await carer(), `${HOME}/nannyShifts/new`), shift(CARER.member)),
  ],
  [
    'a tick on an open shift',
    async (): Promise<unknown> =>
      updateDoc(doc(await carer(), PATHS.openShift), { ticks: { bedtime: ['teeth'] } }),
  ],
  [
    'a new log entry',
    async (): Promise<unknown> =>
      setDoc(doc(await carer(), `${PATHS.openShift}/entries/new`), entry(CARER.member)),
  ],
  [
    'a changed log entry',
    async (): Promise<unknown> =>
      updateDoc(doc(await carer(), PATHS.entry), { note: 'Ate half the pasta' }),
  ],
  [
    'a photo update',
    async (): Promise<unknown> =>
      setDoc(doc(await carer(), `${PATHS.openShift}/photoUpdates/new`), photoUpdate(CARER.member)),
  ],
  [
    'a new person who may collect',
    async (): Promise<unknown> =>
      setDoc(doc(await family(), `${HOME}/nannyPickupPeople/new`), pickupPerson(ADMIN.member)),
  ],
  [
    'a changed person who may collect',
    async (): Promise<unknown> =>
      updateDoc(doc(await family(), V2_PATHS.person), { relationship: 'Aunt' }),
  ],
  [
    'a school run',
    async (): Promise<unknown> =>
      setDoc(doc(await family(), V2_PATHS.run), schoolRun(ADMIN.member)),
  ],
  [
    'a pickup change',
    async (): Promise<unknown> =>
      setDoc(doc(await family(), V2_PATHS.change), pickupChange(ADMIN.member)),
  ],
  [
    'a booked shift',
    async (): Promise<unknown> =>
      setDoc(doc(await family(), `${V2_PATHS.bookings}/new`), booking(CARER.member, 120, 300)),
  ],
  [
    'a new house code',
    async (): Promise<unknown> =>
      setDoc(doc(await family(), `${HOME}/nannySecrets/gate`), secret(ADMIN.member)),
  ],
  [
    'a changed house code',
    async (): Promise<unknown> =>
      updateDoc(doc(await family(), V2_PATHS.secret), { value: '1970' }),
  ],
];

const STILL_REMOVED: readonly (readonly [string, () => Promise<unknown>])[] = [
  ['a child card', async (): Promise<unknown> => deleteDoc(doc(await family(), PATHS.card))],
  ['a contact', async (): Promise<unknown> => deleteDoc(doc(await family(), PATHS.contact))],
  [
    'a place in the guide',
    async (): Promise<unknown> => deleteDoc(doc(await family(), PATHS.spot)),
  ],
  ['a house rule', async (): Promise<unknown> => deleteDoc(doc(await family(), PATHS.rule))],
  ['a checklist', async (): Promise<unknown> => deleteDoc(doc(await family(), PATHS.checklist))],
  ['her own log entry', async (): Promise<unknown> => deleteDoc(doc(await carer(), PATHS.entry))],
  ['her own photo update', async (): Promise<unknown> => deleteDoc(doc(await carer(), SENT))],
  [
    'a person who may collect',
    async (): Promise<unknown> => deleteDoc(doc(await family(), V2_PATHS.person)),
  ],
  ['a school run', async (): Promise<unknown> => deleteDoc(doc(await family(), V2_PATHS.run))],
  [
    'a pickup change',
    async (): Promise<unknown> => deleteDoc(doc(await family(), V2_PATHS.change)),
  ],
  ['a booked shift', async (): Promise<unknown> => deleteDoc(doc(await family(), BOOKING))],
  ['a house code', async (): Promise<unknown> => deleteDoc(doc(await family(), V2_PATHS.secret))],
];

beforeEach(async () => {
  await clearData();
  await givenAHubWithTwoCarers();
  await givenData(async (db) => {
    const at = new Date();
    await setDoc(doc(db, SENT), { ...photoUpdate(CARER.member), createdAt: at });
    await setDoc(doc(db, V2_PATHS.person), { ...pickupPerson(ADMIN.member), createdAt: at });
    await setDoc(doc(db, V2_PATHS.run), { ...schoolRun(ADMIN.member), updatedAt: at });
    await setDoc(doc(db, V2_PATHS.change), { ...pickupChange(ADMIN.member), updatedAt: at });
    await setDoc(doc(db, BOOKING), { ...booking(CARER.member, 120, 300), createdAt: at });
  });
});

describe('a Premium household', () => {
  it.each(PREMIUM_WRITES)('writes %s', async (_, write) => {
    await assertSucceeds(write());
  });
});

describe.each(['free', 'lapsed'] as const)('a %s household and the nanny hub', (state) => {
  beforeEach((): Promise<void> => givenNannyPremium(state));

  it.each(PREMIUM_WRITES)('is refused %s', async (_, write) => {
    await assertFails(write());
  });

  it.each(STILL_REMOVED)('still removes %s', async (_, remove) => {
    await assertSucceeds(remove());
  });

  it('still reads everything it made', async () => {
    const db = await carer();
    for (const path of [
      PATHS.card,
      PATHS.contact,
      PATHS.sheet,
      PATHS.spot,
      PATHS.rule,
      PATHS.checklist,
      PATHS.openShift,
      PATHS.entry,
      PATHS.summary,
      SENT,
      V2_PATHS.person,
      V2_PATHS.run,
      V2_PATHS.change,
      BOOKING,
    ]) {
      await assertSucceeds(getDoc(doc(db, path)));
    }
    await assertSucceeds(getDoc(doc(await family(), V2_PATHS.secret)));
  });

  it('still lets a shift-only carer name the booking that lets them in', async () => {
    await givenShiftOnly(CARER.member);
    const stored = await getDoc(doc(await family(), BOOKING));
    await assertSucceeds(
      setDoc(doc(await carer(), `${V2_PATHS.passes}/${CARER.member}`), {
        bookingId: 'saturday',
        startsAt: stored.get('startsAt') as unknown,
        endsAt: stored.get('endsAt') as unknown,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('still shows a carer on a booked shift the house codes', async () => {
    await givenABookingAndPass({
      bookingId: 'now',
      carerMemberId: CARER.member,
      startsInMinutes: -30,
      endsInMinutes: 120,
    });
    await assertSucceeds(getDoc(doc(await carer(), V2_PATHS.secret)));
  });
});
