import {
  Timestamp,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { HOME, HOUSEHOLD, KID_DEVICE, PEOPLE } from './access_fixture';
import { CARER, CHILD, PATHS, entry, givenAHubOfEveryRole, shift } from './nanny_fixture';
import { asKid, asUser, assertFails, assertSucceeds, clearData } from './rules_harness';

/**
 * A shift and its handover log (nanny-hub ADR-0002): started by a client,
 * ticked and logged while open, ended only by `endNannyShift`, and summarised
 * only by it. Everything is the `nannyHub` grant at `edit`; the log is changed
 * only by whoever wrote it, and only while the shift is open.
 */

beforeEach(async () => {
  await clearData();
  await givenAHubOfEveryRole();
});

describe('starting a shift', () => {
  it('lets the carer start their own', async () => {
    const db = await asUser(CARER.uid);
    await assertSucceeds(setDoc(doc(db, `${HOME}/nannyShifts/new`), shift(CARER.member)));
  });

  it('lets a parent start one for the carer, who may not have their phone', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(
      setDoc(doc(db, `${HOME}/nannyShifts/new`), shift(PEOPLE.parent.member, CARER.member)),
    );
  });

  it('refuses a carer starting one in somebody else’s name', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(
      setDoc(doc(db, `${HOME}/nannyShifts/new`), shift(CARER.member, PEOPLE.viewer.member)),
    );
    await assertFails(setDoc(doc(db, `${HOME}/nannyShifts/new`), shift(PEOPLE.admin.member)));
  });

  it('refuses a shift that starts ended, pre-ticked, or at a time the client chose', async () => {
    const db = await asUser(CARER.uid);
    const path = `${HOME}/nannyShifts/new`;
    await assertFails(setDoc(doc(db, path), { ...shift(CARER.member), status: 'ended' }));
    await assertFails(setDoc(doc(db, path), { ...shift(CARER.member), ticks: { 'x:y': true } }));
    await assertFails(setDoc(doc(db, path), { ...shift(CARER.member), startedAt: new Date() }));
  });

  it('refuses anybody whose hub is not edit', async () => {
    for (const person of ['viewer', 'cleaner', 'kid'] as const) {
      const db = await asUser(PEOPLE[person].uid);
      await assertFails(setDoc(doc(db, `${HOME}/nannyShifts/new`), shift(PEOPLE[person].member)));
    }
  });
});

describe('an open shift', () => {
  it('has its checklists ticked and unticked by whoever writes the hub', async () => {
    const carer = await asUser(CARER.uid);
    await assertSucceeds(updateDoc(doc(carer, PATHS.openShift), { 'ticks.bedtime:teeth': true }));
    const parent = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(
      updateDoc(doc(parent, PATHS.openShift), { 'ticks.bedtime:teeth': deleteField() }),
    );
  });

  it('is never ended, reassigned or deleted by a client — ending is the Function’s', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(
      updateDoc(doc(db, PATHS.openShift), { status: 'ended', endedAt: serverTimestamp() }),
    );
    await assertFails(updateDoc(doc(db, PATHS.openShift), { carerMemberId: PEOPLE.viewer.member }));
    await assertFails(deleteDoc(doc(await asUser(PEOPLE.admin.uid), PATHS.openShift)));
  });

  it('refuses a tick from a helper at view', async () => {
    const db = await asUser(PEOPLE.viewer.uid);
    await assertFails(updateDoc(doc(db, PATHS.openShift), { 'ticks.bedtime:teeth': true }));
  });

  it('and an ended shift takes no more ticks', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(updateDoc(doc(db, PATHS.endedShift), { 'ticks.bedtime:teeth': true }));
  });
});

describe('the handover log', () => {
  const newEntry = `${HOME}/nannyShifts/tonight/entries/new`;

  it('takes a note, a mood or a photo from the carer while the shift is open', async () => {
    const db = await asUser(CARER.uid);
    await assertSucceeds(setDoc(doc(db, newEntry), entry(CARER.member)));
    await assertSucceeds(
      setDoc(
        doc(db, `${newEntry}-mood`),
        entry(CARER.member, { kind: 'mood', note: null, mood: 'tired' }),
      ),
    );
    await assertSucceeds(
      setDoc(
        doc(db, `${newEntry}-photo`),
        entry(CARER.member, { note: null, photoId: 'photo_0001' }),
      ),
    );
  });

  it('takes a nap logged when it ended, set back to when it began', async () => {
    const db = await asUser(CARER.uid);
    const earlier = Timestamp.fromMillis(Date.now() - 90 * 60 * 1000);
    await assertSucceeds(
      setDoc(doc(db, newEntry), entry(CARER.member, { kind: 'nap', at: earlier })),
    );
  });

  it('refuses an entry that says nothing, is from the future, or is of no known kind', async () => {
    const db = await asUser(CARER.uid);
    const later = Timestamp.fromMillis(Date.now() + 60 * 60 * 1000);
    await assertFails(setDoc(doc(db, newEntry), entry(CARER.member, { note: null })));
    await assertFails(setDoc(doc(db, newEntry), entry(CARER.member, { at: later })));
    await assertFails(setDoc(doc(db, newEntry), entry(CARER.member, { kind: 'party' })));
    await assertFails(setDoc(doc(db, newEntry), entry(CARER.member, { mood: 'grumpy' })));
  });

  it('refuses an entry in somebody else’s name', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(setDoc(doc(db, newEntry), entry(PEOPLE.parent.member)));
  });

  it('refuses anything logged against a shift that has ended', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(
      setDoc(doc(db, `${HOME}/nannyShifts/last-week/entries/late`), entry(CARER.member)),
    );
    await assertFails(updateDoc(doc(db, PATHS.endedEntry), { note: 'Changed my mind' }));
    await assertFails(deleteDoc(doc(db, PATHS.endedEntry)));
  });

  it('is changed and deleted only by whoever wrote it', async () => {
    const parent = await asUser(PEOPLE.parent.uid);
    await assertFails(updateDoc(doc(parent, PATHS.entry), { note: 'Rewritten' }));
    await assertFails(deleteDoc(doc(parent, PATHS.entry)));
    const carer = await asUser(CARER.uid);
    await assertSucceeds(updateDoc(doc(carer, PATHS.entry), { note: 'And pudding' }));
    await assertFails(updateDoc(doc(carer, PATHS.entry), { byMemberId: PEOPLE.parent.member }));
    await assertSucceeds(deleteDoc(doc(carer, PATHS.entry)));
  });

  it('is read by a helper at view, and never written by them or the kid’s tablet', async () => {
    const viewer = await asUser(PEOPLE.viewer.uid);
    await assertSucceeds(getDoc(doc(viewer, PATHS.entry)));
    await assertFails(setDoc(doc(viewer, newEntry), entry(PEOPLE.viewer.member)));
    const tablet = await asKid(KID_DEVICE, { householdId: HOUSEHOLD, memberId: CHILD });
    await assertFails(setDoc(doc(tablet, newEntry), entry(CHILD)));
  });
});

describe('a shift’s summary', () => {
  it('is read by whoever reads the hub', async () => {
    await assertSucceeds(getDoc(doc(await asUser(PEOPLE.parent.uid), PATHS.summary)));
    await assertSucceeds(getDoc(doc(await asUser(CARER.uid), PATHS.summary)));
  });

  it('is written by no client at all, family included — only `endNannyShift`', async () => {
    for (const person of ['admin', 'carer'] as const) {
      const db = await asUser(PEOPLE[person].uid);
      await assertFails(
        setDoc(doc(db, `${HOME}/nannyShiftSummaries/tonight`), { carerMemberId: CARER.member }),
      );
      await assertFails(updateDoc(doc(db, PATHS.summary), { delivery: { state: 'sent' } }));
      await assertFails(deleteDoc(doc(db, PATHS.summary)));
    }
  });

  it('is not read by the cleaner', async () => {
    await assertFails(getDoc(doc(await asUser(PEOPLE.cleaner.uid), PATHS.summary)));
  });
});
