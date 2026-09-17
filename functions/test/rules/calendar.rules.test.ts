import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const SAM_MEMBER = 'm-sam';
const THANDI_MEMBER = 'm-thandi';
const EVENTS = `households/${HOUSEHOLD}/events`;
const SKIPS = `households/${HOUSEHOLD}/eventExceptions`;
const DATE = '2026-09-22';

async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
    });
    for (const [id, name, role, claimedBy] of [
      [SAM_MEMBER, 'Sam', 'admin', SAM],
      [THANDI_MEMBER, 'Thandi', 'helper', THANDI],
    ] as const) {
      await setDoc(doc(db, `households/${HOUSEHOLD}/members/${id}`), {
        displayName: name,
        color: 'violet',
        role,
        claimedBy,
      });
    }
    await setDoc(doc(db, `${EVENTS}/school-run`), {
      title: 'School run',
      note: null,
      date: DATE,
      startMinute: 450,
      endMinute: 510,
      recurrence: { frequency: 'weekly', interval: 1, weekdays: [2], until: null },
      memberIds: [THANDI_MEMBER],
      createdBy: THANDI_MEMBER,
      createdAt: new Date(),
    });
  });
}

const newEvent = {
  title: 'Dentist',
  note: null,
  date: DATE,
  startMinute: 600,
  endMinute: 660,
  recurrence: null,
  memberIds: [],
  createdBy: THANDI_MEMBER,
  createdAt: serverTimestamp(),
};

describe('events/{eventId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets any member read the calendar, and denies a stranger', async () => {
    await assertSucceeds(getDoc(doc(await asUser(SAM), `${EVENTS}/school-run`)));
    await assertFails(getDoc(doc(await asUser(STRANGER), `${EVENTS}/school-run`)));
  });

  it('lets a member add an event in their own name', async () => {
    await assertSucceeds(setDoc(doc(await asUser(THANDI), `${EVENTS}/dentist`), newEvent));
  });

  it('lets an all-day event have no times at all', async () => {
    await assertSucceeds(
      setDoc(doc(await asUser(THANDI), `${EVENTS}/birthday`), {
        ...newEvent,
        startMinute: null,
        endMinute: null,
      }),
    );
  });

  it('denies a time that is not a minute of the day', async () => {
    const db = await asUser(THANDI);
    await assertFails(setDoc(doc(db, `${EVENTS}/a`), { ...newEvent, startMinute: 1440 }));
    await assertFails(setDoc(doc(db, `${EVENTS}/b`), { ...newEvent, startMinute: -1 }));
    await assertFails(setDoc(doc(db, `${EVENTS}/c`), { ...newEvent, startMinute: '09:00' }));
  });

  it('denies an event in somebody else"s name, or with no title or day', async () => {
    const db = await asUser(THANDI);
    await assertFails(setDoc(doc(db, `${EVENTS}/a`), { ...newEvent, createdBy: SAM_MEMBER }));
    await assertFails(setDoc(doc(db, `${EVENTS}/b`), { ...newEvent, title: '' }));
    await assertFails(setDoc(doc(db, `${EVENTS}/c`), { ...newEvent, date: '' }));
  });

  it('lets the creator edit their own event, and an admin edit anybody"s', async () => {
    await assertSucceeds(
      updateDoc(doc(await asUser(THANDI), `${EVENTS}/school-run`), {
        startMinute: 460,
      }),
    );
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), `${EVENTS}/school-run`), {
        title: 'School run (early)',
      }),
    );
  });

  it('denies a non-creator, non-admin editing an event', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${EVENTS}/sams-thing`), {
        ...newEvent,
        createdBy: SAM_MEMBER,
        createdAt: new Date(),
      });
    });
    await assertFails(
      updateDoc(doc(await asUser(THANDI), `${EVENTS}/sams-thing`), {
        title: 'Mine now',
      }),
    );
  });

  it('denies rewriting who created an event', async () => {
    await assertFails(
      updateDoc(doc(await asUser(SAM), `${EVENTS}/school-run`), {
        createdBy: SAM_MEMBER,
      }),
    );
  });

  it('lets the creator or an admin delete, and denies anybody else', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${EVENTS}/sams-thing`), {
        ...newEvent,
        createdBy: SAM_MEMBER,
        createdAt: new Date(),
      });
    });
    await assertFails(deleteDoc(doc(await asUser(THANDI), `${EVENTS}/sams-thing`)));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${EVENTS}/sams-thing`)));
    await assertSucceeds(deleteDoc(doc(await asUser(THANDI), `${EVENTS}/school-run`)));
  });
});

describe('eventExceptions/{exceptionId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  const skip = {
    eventId: 'school-run',
    occurrenceDate: DATE,
    skippedBy: THANDI_MEMBER,
    skippedAt: serverTimestamp(),
  };

  it('lets any member skip one occurrence', async () => {
    await assertSucceeds(setDoc(doc(await asUser(THANDI), `${SKIPS}/school-run_${DATE}`), skip));
  });

  it('denies skipping in somebody else"s name', async () => {
    await assertFails(setDoc(doc(await asUser(SAM), `${SKIPS}/school-run_${DATE}`), skip));
  });

  it('denies filing a skip under an id that is not its own occurrence', async () => {
    const db = await asUser(THANDI);
    await assertFails(setDoc(doc(db, `${SKIPS}/school-run_2026-09-29`), skip));
    await assertFails(setDoc(doc(db, `${SKIPS}/other_${DATE}`), skip));
  });

  it('denies dating a skip itself', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${SKIPS}/school-run_${DATE}`), {
        ...skip,
        skippedAt: new Date('2000-01-01'),
      }),
    );
  });

  it('is the same write twice, and any member can put the occurrence back', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(setDoc(doc(db, `${SKIPS}/school-run_${DATE}`), skip));
    await assertSucceeds(setDoc(doc(db, `${SKIPS}/school-run_${DATE}`), skip));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${SKIPS}/school-run_${DATE}`)));
  });

  it('denies a stranger everything', async () => {
    const db = await asUser(STRANGER);
    await assertFails(getDoc(doc(db, `${SKIPS}/school-run_${DATE}`)));
    await assertFails(setDoc(doc(db, `${SKIPS}/school-run_${DATE}`), skip));
  });
});
