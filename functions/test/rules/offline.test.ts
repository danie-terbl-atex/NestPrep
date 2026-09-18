import {
  collection,
  disableNetwork,
  doc,
  enableNetwork,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { givenAHouseholdOfTwo, SAM, SAM_MEMBER, THANDI, THANDI_MEMBER } from './household_fixture';
import { stopWatching, watchDoc } from './live_watch';
import { asUser, givenData, type Firestore } from './rules_harness';
import { weeklyOn } from '../recurrence_shape';

/**
 * A phone in a shop basement, or a car on the N2, still has to work. The app
 * does not implement that — Firestore's write queue and local cache do, and
 * offline persistence is on — but "the SDK should handle it" is not
 * verification. These tests take a real client off the network, write to it, put
 * it back, and check what the other member ends up being told.
 *
 * What they cannot reach is the Flutter widget: they prove the client SDK and
 * the rules behave, not that a screen redrew. That part stays a device check.
 */

const DATE = '2026-09-18';
const WEEK = '2026-09-14';

const offline: Firestore[] = [];

/** Takes a client off the network, and guarantees it comes back. */
async function goOffline(db: Firestore): Promise<void> {
  offline.push(db);
  await disableNetwork(db);
}

async function reconnectEverything(): Promise<void> {
  while (offline.length > 0) {
    const db = offline.pop();
    if (db) await enableNetwork(db);
  }
}

describe('a member who is offline', () => {
  let home = '';
  let sam: Firestore;
  let thandi: Firestore;

  beforeEach(async () => {
    home = await givenAHouseholdOfTwo();
    sam = await asUser(SAM);
    thandi = await asUser(THANDI);
  });

  afterEach(async () => {
    stopWatching();
    await reconnectEverything();
  });

  it('sees their own write straight away, marked as not yet sent', async () => {
    await goOffline(thandi);

    // Deliberately not awaited: offline, this settles only on reconnect.
    void setDoc(doc(thandi, `${home}/groceryItems/eggs`), {
      name: 'Eggs',
      quantity: null,
      addedBy: THANDI_MEMBER,
      addedAt: serverTimestamp(),
      boughtAt: null,
      boughtBy: null,
    });

    const own = await getDoc(doc(thandi, `${home}/groceryItems/eggs`));
    expect(own.get('name')).toBe('Eggs');
    expect(own.metadata.hasPendingWrites).toBe(true);
  });

  it('is invisible to everyone else until they are back', async () => {
    await goOffline(thandi);

    void setDoc(doc(thandi, `${home}/groceryItems/eggs`), {
      name: 'Eggs',
      quantity: null,
      addedBy: THANDI_MEMBER,
      addedAt: serverTimestamp(),
      boughtAt: null,
      boughtBy: null,
    });

    const nothingYet = await getDoc(doc(sam, `${home}/groceryItems/eggs`));
    expect(nothingYet.exists()).toBe(false);

    const arrives = watchDoc(sam, `${home}/groceryItems/eggs`, (item) => item.exists());
    await enableNetwork(thandi);
    expect((await arrives).get('name')).toBe('Eggs');
  });

  it('has their tick arrive on the other phone when they reconnect', async () => {
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
    await goOffline(thandi);

    void updateDoc(doc(thandi, `${home}/groceryItems/milk`), {
      boughtAt: serverTimestamp(),
      boughtBy: THANDI_MEMBER,
    });

    const arrives = watchDoc(
      sam,
      `${home}/groceryItems/milk`,
      (item) => item.get('boughtBy') === THANDI_MEMBER,
    );
    await enableNetwork(thandi);
    await expect(arrives).resolves.toBeDefined();
  });

  it('has a task they completed on a plane counted when they land', async () => {
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
    await goOffline(thandi);

    void setDoc(doc(thandi, `${home}/taskCompletions/bins_${DATE}`), {
      taskId: 'bins',
      occurrenceDate: DATE,
      completedBy: THANDI_MEMBER,
      completedFor: THANDI_MEMBER,
      completedAt: serverTimestamp(),
    });

    const arrives = watchDoc(sam, `${home}/taskCompletions/bins_${DATE}`, (record) =>
      record.exists(),
    );
    await enableNetwork(thandi);
    expect((await arrives).get('completedBy')).toBe(THANDI_MEMBER);
  });

  it('has an event added on a plane on the week when they land', async () => {
    await goOffline(thandi);

    void setDoc(doc(thandi, `${home}/events/school-run`), {
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

    const arrives = watchDoc(sam, `${home}/events/school-run`, (event) => event.exists());
    await enableNetwork(thandi);
    expect((await arrives).get('title')).toBe('School run');
  });

  it('is still refused what the rules refuse — the queue is not a way in', async () => {
    await goOffline(thandi);

    // A helper may not write a routine. Offline the client takes it locally; the
    // server is the one that decides, and it decides on reconnect.
    const refused = setDoc(doc(thandi, `${home}/routines/laundry`), {
      name: 'Laundry Day',
      recurrence: weeklyOn([6]),
      defaultAssigneeIds: [],
      createdBy: THANDI_MEMBER,
      createdAt: serverTimestamp(),
    });

    await enableNetwork(thandi);
    await expect(refused).rejects.toThrow();

    const after = await getDocs(collection(sam, `${home}/routines`));
    expect(after.empty).toBe(true);
  });
});

describe('two members who both set the same meal slot offline', () => {
  let home = '';
  let sam: Firestore;
  let thandi: Firestore;

  beforeEach(async () => {
    home = await givenAHouseholdOfTwo();
    sam = await asUser(SAM);
    thandi = await asUser(THANDI);
    await givenData(async (db) => {
      for (const [id, name] of [
        ['spaghetti', 'Spaghetti'],
        ['curry', 'Curry'],
      ] as const) {
        await setDoc(doc(db, `${home}/meals/${id}`), {
          name,
          nameKey: id,
          addedBy: SAM_MEMBER,
          createdAt: new Date(),
        });
      }
    });
  });

  afterEach(async () => {
    stopWatching();
    await reconnectEverything();
  });

  it('end up on one meal, the one written later', async () => {
    await goOffline(sam);
    await goOffline(thandi);

    const plan = `${home}/mealPlans/${WEEK}`;
    void setDoc(doc(sam, plan), { slots: { '2_dinner': 'curry' } });
    void setDoc(doc(thandi, plan), { slots: { '2_dinner': 'spaghetti' } });

    // Sam's queue drains first, so Thandi is unambiguously the later write.
    await enableNetwork(sam);
    await getDoc(doc(sam, plan));
    await enableNetwork(thandi);

    const settled = watchDoc(sam, plan, (week) => week.get('slots.2_dinner') === 'spaghetti');
    await expect(settled).resolves.toBeDefined();

    const asThandi = await getDoc(doc(thandi, plan));
    expect(asThandi.get('slots.2_dinner')).toBe('spaghetti');
  });
});
