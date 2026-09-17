import { deleteDoc, doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { givenAHouseholdOfTwo, SAM, SAM_MEMBER, THANDI, THANDI_MEMBER } from './household_fixture';
import { stopWatching, watchDoc, watchGone } from './live_watch';
import { asUser, givenData, type Firestore } from './rules_harness';

/**
 * One member writes; another member's open listener is told, without asking
 * again. That is the promise the verdict makes — "it updates live on every other
 * member's phone" — and until this file existed the only way to check it was two
 * phones and a spare pair of hands.
 *
 * These are two real signed-in clients against the real rules engine, so a write
 * the rules would refuse fails here too. What they cannot reach is the Flutter
 * widget: they prove the client was told, not that a screen redrew.
 */

const DATE = '2026-09-18';

describe('one member writes, another member is told', () => {
  let home = '';
  let sam: Firestore;
  let thandi: Firestore;

  beforeEach(async () => {
    home = await givenAHouseholdOfTwo();
    sam = await asUser(SAM);
    thandi = await asUser(THANDI);
  });

  afterEach(() => {
    stopWatching();
  });

  it('a grocery item added by one appears for the other without asking again', async () => {
    const seen = watchDoc(sam, `${home}/groceryItems/eggs`, (item) => item.get('name') === 'Eggs');
    await setDoc(doc(thandi, `${home}/groceryItems/eggs`), {
      name: 'Eggs',
      quantity: 'a dozen',
      addedBy: THANDI_MEMBER,
      addedAt: serverTimestamp(),
      boughtAt: null,
      boughtBy: null,
    });

    expect((await seen).get('addedBy')).toBe(THANDI_MEMBER);
  });

  it('a tick by one strikes it through for the other', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${home}/groceryItems/milk`), {
        name: 'Milk',
        quantity: null,
        addedBy: SAM_MEMBER,
        addedAt: new Date(),
        boughtAt: null,
        boughtBy: null,
      });
    });

    const seen = watchDoc(
      sam,
      `${home}/groceryItems/milk`,
      (item) => item.get('boughtBy') === THANDI_MEMBER,
    );
    await updateDoc(doc(thandi, `${home}/groceryItems/milk`), {
      boughtAt: serverTimestamp(),
      boughtBy: THANDI_MEMBER,
    });

    expect((await seen).get('boughtAt')).not.toBeNull();
  });

  it('a task added by one appears for the other', async () => {
    const seen = watchDoc(sam, `${home}/tasks/bins`, (task) => task.get('title') === 'Bins');
    await setDoc(doc(thandi, `${home}/tasks/bins`), {
      title: 'Bins',
      note: null,
      dueDate: DATE,
      recurrence: null,
      assigneeIds: [],
      createdBy: THANDI_MEMBER,
      routineId: null,
      createdAt: serverTimestamp(),
    });

    await expect(seen).resolves.toBeDefined();
  });

  it('a task completed by one shows done for the other', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${home}/tasks/bins`), {
        title: 'Bins',
        note: null,
        dueDate: DATE,
        recurrence: null,
        assigneeIds: [],
        createdBy: SAM_MEMBER,
        routineId: null,
        createdAt: new Date(),
      });
    });

    const seen = watchDoc(sam, `${home}/taskCompletions/bins_${DATE}`, (record) => record.exists());
    await setDoc(doc(thandi, `${home}/taskCompletions/bins_${DATE}`), {
      taskId: 'bins',
      occurrenceDate: DATE,
      completedBy: THANDI_MEMBER,
      completedFor: THANDI_MEMBER,
      completedAt: serverTimestamp(),
    });

    expect((await seen).get('completedBy')).toBe(THANDI_MEMBER);
  });

  it('an event added by one appears on the week the other is looking at', async () => {
    const seen = watchDoc(
      sam,
      `${home}/events/school-run`,
      (event) => event.get('title') === 'School run',
    );
    await setDoc(doc(thandi, `${home}/events/school-run`), {
      title: 'School run',
      note: null,
      date: DATE,
      startMinute: 450,
      endMinute: 510,
      recurrence: null,
      memberIds: [],
      createdBy: THANDI_MEMBER,
      createdAt: serverTimestamp(),
    });

    expect((await seen).get('startMinute')).toBe(450);
  });

  it('an occurrence skipped by one disappears for the other', async () => {
    const seen = watchDoc(sam, `${home}/eventExceptions/school-run_${DATE}`, (skip) =>
      skip.exists(),
    );
    await setDoc(doc(thandi, `${home}/eventExceptions/school-run_${DATE}`), {
      eventId: 'school-run',
      occurrenceDate: DATE,
      skippedBy: THANDI_MEMBER,
      skippedAt: serverTimestamp(),
    });

    expect((await seen).get('occurrenceDate')).toBe(DATE);
  });

  it('a meal typed by one joins the library the other picks from', async () => {
    const seen = watchDoc(
      sam,
      `${home}/meals/spaghetti`,
      (meal) => meal.get('name') === 'Spaghetti',
    );
    await setDoc(doc(thandi, `${home}/meals/spaghetti`), {
      name: 'Spaghetti',
      nameKey: 'spaghetti',
      addedBy: THANDI_MEMBER,
      createdAt: serverTimestamp(),
    });

    await expect(seen).resolves.toBeDefined();
  });

  it('a slot filled by one fills on the week the other is planning', async () => {
    const seen = watchDoc(
      sam,
      `${home}/mealPlans/2026-09-14`,
      (plan) => plan.get('slots.2_dinner') === 'spaghetti',
    );
    await setDoc(doc(thandi, `${home}/mealPlans/2026-09-14`), {
      slots: { '2_dinner': 'spaghetti' },
    });

    await expect(seen).resolves.toBeDefined();
  });

  it('a member added by the admin appears for everybody', async () => {
    const seen = watchDoc(
      thandi,
      `${home}/members/m-kid`,
      (member) => member.get('displayName') === 'Kid',
    );
    await setDoc(doc(sam, `${home}/members/m-kid`), {
      displayName: 'Kid',
      color: 'sky',
      role: 'member',
      claimedBy: null,
      createdAt: serverTimestamp(),
    });

    expect((await seen).get('role')).toBe('member');
  });

  it('a deletion by one removes it for the other', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${home}/groceryItems/milk`), {
        name: 'Milk',
        quantity: null,
        addedBy: THANDI_MEMBER,
        addedAt: new Date(),
        boughtAt: null,
        boughtBy: null,
      });
    });

    const gone = watchGone(sam, `${home}/groceryItems/milk`);
    await deleteDoc(doc(thandi, `${home}/groceryItems/milk`));

    await expect(gone).resolves.toBeDefined();
  });
});
