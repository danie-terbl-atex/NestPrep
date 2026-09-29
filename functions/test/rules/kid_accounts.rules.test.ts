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
import { beforeAll, describe, it } from 'vitest';

import {
  asKid,
  asUser,
  assertFails,
  assertSucceeds,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * What a kid device may do, and — mostly — what it may not (accounts ADR-0003).
 *
 * A kid device is not a member. It reaches its household only through the
 * household's `kids` map, and only where a block grants it: the household
 * itself, its own profile, the chores that name it, routines, its own
 * completions, and the meal plan. Every other collection refuses it by
 * default, which is what most of this file proves.
 */

const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const KID = 'kid_mia-tablet';
const REVOKED_KID = 'kid_lost-phone';
const HOME = 'households/h-kids';
const MIA = 'm-mia';
const LEO = 'm-leo';
const DATE = '2026-09-29';
const miasTablet = (): Promise<Firestore> => asKid(KID, { householdId: 'h-kids', memberId: MIA });

function task(title: string, assigneeIds: string[], routineId: string | null = null): object {
  return {
    title,
    note: null,
    dueDate: DATE,
    recurrence: null,
    assigneeIds,
    createdBy: 'm-sam',
    routineId,
    createdAt: new Date(),
  };
}

function completion(taskId: string, by: string, forMember: string): object {
  return {
    taskId,
    occurrenceDate: DATE,
    completedBy: by,
    completedFor: forMember,
    completedAt: serverTimestamp(),
  };
}

beforeAll(async () => {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, HOME), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
      kids: { [KID]: MIA },
    });
    for (const [id, name, role, claimedBy] of [
      ['m-sam', 'Sam', 'admin', SAM],
      ['m-thandi', 'Thandi', 'helper', THANDI],
      [MIA, 'Mia', 'member', null],
      [LEO, 'Leo', 'member', null],
    ] as const) {
      await setDoc(doc(db, `${HOME}/members/${id}`), {
        displayName: name,
        color: 'violet',
        role,
        claimedBy,
      });
    }
    await setDoc(doc(db, `${HOME}/tasks/dishes`), task('Dishes', [MIA]));
    await setDoc(doc(db, `${HOME}/tasks/feed-cat`), task('Feed the cat', [MIA], 'r-morning'));
    await setDoc(doc(db, `${HOME}/tasks/homework-leo`), task('Homework', [LEO]));
    await setDoc(doc(db, `${HOME}/tasks/bins`), task('Bins', []));
    await setDoc(doc(db, `${HOME}/routines/r-morning`), {
      name: 'Morning',
      firstDate: DATE,
      recurrence: null,
      defaultAssigneeIds: [MIA],
      color: 'mint',
      createdBy: 'm-sam',
      createdAt: new Date(),
    });
    await setDoc(doc(db, `${HOME}/taskCompletions/homework-leo_${DATE}`), {
      ...completion('homework-leo', LEO, LEO),
      completedAt: new Date(),
    });
    await setDoc(doc(db, `${HOME}/taskCompletions/feed-cat_${DATE}`), {
      ...completion('feed-cat', MIA, MIA),
      completedAt: new Date(),
    });
    await setDoc(doc(db, `${HOME}/meals/pasta`), {
      name: 'Pasta',
      nameKey: 'pasta',
      addedBy: 'm-sam',
      createdAt: new Date(),
    });
    await setDoc(doc(db, `${HOME}/mealPlans/2026-09-28`), { slots: { '2_lunch': 'pasta' } });
    await setDoc(doc(db, `${HOME}/groceryItems/milk`), { name: 'Milk' });
    await setDoc(doc(db, `${HOME}/events/dentist`), { title: 'Dentist' });
    await setDoc(doc(db, `${HOME}/documentFolders/school`), { name: 'School' });
    await setDoc(doc(db, `${HOME}/documents/passport`), { name: 'Passport' });
    await setDoc(doc(db, `${HOME}/memberLocations/m-sam`), { accuracyMetres: 5 });
    await setDoc(doc(db, `${HOME}/kidDevices/${KID}`), {
      memberId: MIA,
      label: 'Tablet',
      pairedBy: SAM,
      pairedAt: new Date(),
    });
    await setDoc(doc(db, 'kidPairings/ABC234'), { householdId: 'h-kids', memberId: LEO });
    await setDoc(doc(db, 'invites/ABCD2345'), { householdId: 'h-kids', memberId: LEO });
  });
});

describe('a kid device reads its own corner of the household', () => {
  it('the household itself, for its name and its zone', async () => {
    await assertSucceeds(getDoc(doc(await miasTablet(), HOME)));
  });

  it('its own profile', async () => {
    await assertSucceeds(getDoc(doc(await miasTablet(), `${HOME}/members/${MIA}`)));
  });

  it('the chores that name it — the query it actually makes', async () => {
    const db = await miasTablet();
    await assertSucceeds(
      getDocs(query(collection(db, `${HOME}/tasks`), where('assigneeIds', 'array-contains', MIA))),
    );
    await assertSucceeds(getDoc(doc(db, `${HOME}/tasks/dishes`)));
  });

  it('routines, so a chore in one lands on the right day', async () => {
    await assertSucceeds(getDoc(doc(await miasTablet(), `${HOME}/routines/r-morning`)));
  });

  it('its own completions, windowed', async () => {
    const db = await miasTablet();
    await assertSucceeds(
      getDocs(
        query(
          collection(db, `${HOME}/taskCompletions`),
          where('completedFor', '==', MIA),
          where('occurrenceDate', '>=', '2026-09-22'),
          where('occurrenceDate', '<=', DATE),
        ),
      ),
    );
  });

  it("the household's meals and this week's plan", async () => {
    const db = await miasTablet();
    await assertSucceeds(getDoc(doc(db, `${HOME}/meals/pasta`)));
    await assertSucceeds(getDoc(doc(db, `${HOME}/mealPlans/2026-09-28`)));
  });
});

describe('and nothing about anybody else', () => {
  it('not a sibling’s profile, and not the list of profiles', async () => {
    const db = await miasTablet();
    await assertFails(getDoc(doc(db, `${HOME}/members/${LEO}`)));
    await assertFails(getDocs(collection(db, `${HOME}/members`)));
  });

  it('not every task, a sibling’s chores, or chores for anyone', async () => {
    const db = await miasTablet();
    await assertFails(getDocs(collection(db, `${HOME}/tasks`)));
    await assertFails(
      getDocs(query(collection(db, `${HOME}/tasks`), where('assigneeIds', 'array-contains', LEO))),
    );
    await assertFails(getDoc(doc(db, `${HOME}/tasks/homework-leo`)));
    await assertFails(getDoc(doc(db, `${HOME}/tasks/bins`)));
  });

  it('not a sibling’s completions, and not all of them', async () => {
    const db = await miasTablet();
    await assertFails(getDoc(doc(db, `${HOME}/taskCompletions/homework-leo_${DATE}`)));
    await assertFails(getDocs(collection(db, `${HOME}/taskCompletions`)));
  });

  for (const path of [
    'groceryItems/milk',
    'events/dentist',
    'documentFolders/school',
    'documents/passport',
    'memberLocations/m-sam',
    `kidDevices/${KID}`,
  ]) {
    it(`not ${path.split('/')[0] ?? path}`, async () => {
      await assertFails(getDoc(doc(await miasTablet(), `${HOME}/${path}`)));
    });
  }

  it('not a pairing code or an invite', async () => {
    const db = await miasTablet();
    await assertFails(getDoc(doc(db, 'kidPairings/ABC234')));
    await assertFails(getDoc(doc(db, 'invites/ABCD2345')));
  });
});

describe('a kid device ticks off its own chores', () => {
  it('as itself and for itself', async () => {
    await assertSucceeds(
      setDoc(
        doc(await miasTablet(), `${HOME}/taskCompletions/dishes_${DATE}`),
        completion('dishes', MIA, MIA),
      ),
    );
  });

  it('and unticks one', async () => {
    await assertSucceeds(
      deleteDoc(doc(await miasTablet(), `${HOME}/taskCompletions/feed-cat_${DATE}`)),
    );
  });

  it('but not a sibling’s chore, for the sibling or for itself', async () => {
    const db = await miasTablet();
    const leos = doc(db, `${HOME}/taskCompletions/homework-leo_2026-09-30`);
    await assertFails(
      setDoc(leos, { ...completion('homework-leo', LEO, LEO), occurrenceDate: '2026-09-30' }),
    );
    await assertFails(
      setDoc(leos, { ...completion('homework-leo', MIA, MIA), occurrenceDate: '2026-09-30' }),
    );
  });

  it('not a chore for anyone, which does not name it', async () => {
    await assertFails(
      setDoc(
        doc(await miasTablet(), `${HOME}/taskCompletions/bins_${DATE}`),
        completion('bins', MIA, MIA),
      ),
    );
  });

  it('not in somebody else’s name', async () => {
    await assertFails(
      setDoc(doc(await miasTablet(), `${HOME}/taskCompletions/dishes_2026-09-30`), {
        ...completion('dishes', 'm-sam', MIA),
        occurrenceDate: '2026-09-30',
      }),
    );
  });

  it('not filed against a day it is not about', async () => {
    await assertFails(
      setDoc(
        doc(await miasTablet(), `${HOME}/taskCompletions/dishes_2026-10-01`),
        completion('dishes', MIA, MIA),
      ),
    );
  });

  it('and cannot untick a sibling’s', async () => {
    await assertFails(
      deleteDoc(doc(await miasTablet(), `${HOME}/taskCompletions/homework-leo_${DATE}`)),
    );
  });
});

describe('a kid device changes nothing else', () => {
  it('no household, no membership, no profile', async () => {
    const db = await miasTablet();
    await assertFails(updateDoc(doc(db, HOME), { name: 'Mia’s house' }));
    await assertFails(updateDoc(doc(db, `${HOME}/members/${MIA}`), { displayName: 'Queen Mia' }));
    await assertFails(
      setDoc(doc(db, `${HOME}/members/m-new`), {
        displayName: 'Friend',
        color: 'mint',
        role: 'member',
        claimedBy: null,
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('no tasks and no groceries', async () => {
    const db = await miasTablet();
    await assertFails(setDoc(doc(db, `${HOME}/tasks/new`), task('Skip school', [MIA])));
    await assertFails(setDoc(doc(db, `${HOME}/groceryItems/sweets`), { name: 'Sweets' }));
  });

  it('and no account document, because it has no account', async () => {
    await assertFails(
      setDoc(doc(await miasTablet(), `users/${KID}`), {
        displayName: 'Mia',
        photoUrl: null,
        householdIds: [],
        activeHouseholdId: null,
        createdAt: serverTimestamp(),
        lastSignedInAt: serverTimestamp(),
      }),
    );
  });
});

describe('a revoked device reads nothing at all', () => {
  it('its claim still says Mia, and the household no longer lists it', async () => {
    const lost = await asKid(REVOKED_KID, { householdId: 'h-kids', memberId: MIA });
    await assertFails(getDoc(doc(lost, HOME)));
    await assertFails(getDoc(doc(lost, `${HOME}/members/${MIA}`)));
    await assertFails(
      getDocs(
        query(collection(lost, `${HOME}/tasks`), where('assigneeIds', 'array-contains', MIA)),
      ),
    );
  });
});

describe('the devices list is for the parents who can end them', () => {
  it('an admin reads it', async () => {
    await assertSucceeds(getDocs(collection(await asUser(SAM), `${HOME}/kidDevices`)));
  });

  it('a helper does not', async () => {
    await assertFails(getDocs(collection(await asUser(THANDI), `${HOME}/kidDevices`)));
  });

  it('and nobody writes it, not even an admin', async () => {
    const sam = await asUser(SAM);
    await assertFails(deleteDoc(doc(sam, `${HOME}/kidDevices/${KID}`)));
    await assertFails(setDoc(doc(sam, `${HOME}/kidDevices/kid_fake`), { memberId: MIA }));
    await assertFails(getDoc(doc(sam, 'kidPairings/ABC234')));
  });
});

describe('the adults are unchanged by any of it', () => {
  it('a member still reads every task and completion', async () => {
    const thandi = await asUser(THANDI);
    await assertSucceeds(getDocs(collection(thandi, `${HOME}/tasks`)));
    await assertSucceeds(getDocs(collection(thandi, `${HOME}/taskCompletions`)));
  });

  it('an admin still completes a chore on a kid’s behalf', async () => {
    await assertSucceeds(
      setDoc(doc(await asUser(SAM), `${HOME}/taskCompletions/dishes_2026-09-28`), {
        ...completion('dishes', 'm-sam', MIA),
        occurrenceDate: '2026-09-28',
      }),
    );
  });

  it('and a helper still cannot complete in the kid’s name', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${HOME}/taskCompletions/dishes_2026-09-27`), {
        ...completion('dishes', MIA, MIA),
        occurrenceDate: '2026-09-27',
      }),
    );
  });
});
