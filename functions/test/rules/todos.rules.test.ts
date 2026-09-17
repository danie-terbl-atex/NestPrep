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
const KID_MEMBER = 'm-kid';
const TASKS = `households/${HOUSEHOLD}/tasks`;
const ROUTINES = `households/${HOUSEHOLD}/routines`;
const DONE = `households/${HOUSEHOLD}/taskCompletions`;
const DATE = '2026-09-19';

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
      [KID_MEMBER, 'Kid', 'member', null],
    ] as const) {
      await setDoc(doc(db, `households/${HOUSEHOLD}/members/${id}`), {
        displayName: name,
        color: 'violet',
        role,
        claimedBy,
      });
    }
    // Thandi's task, for Thandi.
    await setDoc(doc(db, `${TASKS}/laundry`), {
      title: 'Laundry',
      note: null,
      dueDate: DATE,
      recurrence: null,
      assigneeIds: [THANDI_MEMBER],
      createdBy: THANDI_MEMBER,
      routineId: null,
      createdAt: new Date(),
    });
    // A task for anyone.
    await setDoc(doc(db, `${TASKS}/bins`), {
      title: 'Bins',
      note: null,
      dueDate: DATE,
      recurrence: null,
      assigneeIds: [],
      createdBy: SAM_MEMBER,
      routineId: null,
      createdAt: new Date(),
    });
    // Kid's task — a profile nobody has claimed.
    await setDoc(doc(db, `${TASKS}/homework`), {
      title: 'Homework',
      note: null,
      dueDate: DATE,
      recurrence: null,
      assigneeIds: [KID_MEMBER],
      createdBy: SAM_MEMBER,
      routineId: null,
      createdAt: new Date(),
    });
  });
}

const newTask = {
  title: 'Water the plants',
  note: null,
  dueDate: DATE,
  recurrence: null,
  assigneeIds: [],
  createdBy: THANDI_MEMBER,
  routineId: null,
  createdAt: serverTimestamp(),
};

function completion(taskId: string, by: string, forMember: string) {
  return {
    taskId,
    occurrenceDate: DATE,
    completedBy: by,
    completedFor: forMember,
    completedAt: serverTimestamp(),
  };
}

describe('tasks/{taskId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets any member read the tasks, and denies a stranger', async () => {
    await assertSucceeds(getDoc(doc(await asUser(THANDI), `${TASKS}/laundry`)));
    await assertFails(getDoc(doc(await asUser(STRANGER), `${TASKS}/laundry`)));
  });

  it('lets a member create a task in their own name', async () => {
    await assertSucceeds(setDoc(doc(await asUser(THANDI), `${TASKS}/plants`), newTask));
  });

  it('denies creating a task in somebody else"s name', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${TASKS}/plants`), {
        ...newTask,
        createdBy: SAM_MEMBER,
      }),
    );
  });

  it('denies a task with no title, no due date, or a chosen creation time', async () => {
    const db = await asUser(THANDI);
    await assertFails(setDoc(doc(db, `${TASKS}/a`), { ...newTask, title: '' }));
    await assertFails(setDoc(doc(db, `${TASKS}/b`), { ...newTask, dueDate: '' }));
    await assertFails(
      setDoc(doc(db, `${TASKS}/c`), { ...newTask, createdAt: new Date('2000-01-01') }),
    );
  });

  it('lets the creator edit their own task, and an admin edit anybody"s', async () => {
    await assertSucceeds(
      updateDoc(doc(await asUser(THANDI), `${TASKS}/laundry`), {
        title: 'Laundry and ironing',
      }),
    );
    await assertSucceeds(
      updateDoc(doc(await asUser(SAM), `${TASKS}/laundry`), { title: 'Laundry' }),
    );
  });

  it('denies a non-creator, non-admin editing a task', async () => {
    await assertFails(updateDoc(doc(await asUser(THANDI), `${TASKS}/bins`), { title: 'Not bins' }));
  });

  it('denies rewriting who created a task', async () => {
    await assertFails(
      updateDoc(doc(await asUser(SAM), `${TASKS}/laundry`), {
        createdBy: SAM_MEMBER,
      }),
    );
  });

  it('lets the creator or an admin delete, and denies anybody else', async () => {
    await assertFails(deleteDoc(doc(await asUser(THANDI), `${TASKS}/bins`)));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${TASKS}/bins`)));
    await assertSucceeds(deleteDoc(doc(await asUser(THANDI), `${TASKS}/laundry`)));
  });
});

describe('routines/{routineId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  const newRoutine = {
    name: 'Laundry Day Tasks',
    firstDate: DATE,
    recurrence: { frequency: 'weekly', interval: 1, weekdays: [6], until: null },
    defaultAssigneeIds: [THANDI_MEMBER],
    color: 'mint',
    createdBy: SAM_MEMBER,
    createdAt: serverTimestamp(),
  };

  it('lets an admin create a routine', async () => {
    await assertSucceeds(setDoc(doc(await asUser(SAM), `${ROUTINES}/laundry-day`), newRoutine));
  });

  it('denies a non-admin creating one, because it moves everybody"s tasks', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${ROUTINES}/laundry-day`), {
        ...newRoutine,
        createdBy: THANDI_MEMBER,
      }),
    );
  });

  it('lets every member read routines', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${ROUTINES}/laundry-day`), {
        ...newRoutine,
        createdAt: new Date(),
      });
    });
    await assertSucceeds(getDoc(doc(await asUser(THANDI), `${ROUTINES}/laundry-day`)));
    await assertFails(getDoc(doc(await asUser(STRANGER), `${ROUTINES}/laundry-day`)));
  });

  it('denies a non-admin changing or deleting one', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${ROUTINES}/laundry-day`), {
        ...newRoutine,
        createdAt: new Date(),
      });
    });
    await assertFails(
      updateDoc(doc(await asUser(THANDI), `${ROUTINES}/laundry-day`), {
        name: 'Mine now',
      }),
    );
    await assertFails(deleteDoc(doc(await asUser(THANDI), `${ROUTINES}/laundry-day`)));
  });
});

describe('taskCompletions/{completionId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets an assignee complete their own occurrence', async () => {
    await assertSucceeds(
      setDoc(
        doc(await asUser(THANDI), `${DONE}/laundry_${DATE}`),
        completion('laundry', THANDI_MEMBER, THANDI_MEMBER),
      ),
    );
  });

  it('lets anybody complete a task that is for anyone', async () => {
    await assertSucceeds(
      setDoc(
        doc(await asUser(THANDI), `${DONE}/bins_${DATE}`),
        completion('bins', THANDI_MEMBER, THANDI_MEMBER),
      ),
    );
  });

  it('denies completing a task that is somebody else"s', async () => {
    await assertFails(
      setDoc(
        doc(await asUser(THANDI), `${DONE}/homework_${DATE}`),
        completion('homework', THANDI_MEMBER, THANDI_MEMBER),
      ),
    );
  });

  it('lets an admin complete on behalf of a profile nobody has claimed', async () => {
    await assertSucceeds(
      setDoc(
        doc(await asUser(SAM), `${DONE}/homework_${DATE}`),
        completion('homework', SAM_MEMBER, KID_MEMBER),
      ),
    );
  });

  it('denies a non-admin completing on somebody else"s behalf', async () => {
    await assertFails(
      setDoc(
        doc(await asUser(THANDI), `${DONE}/homework_${DATE}`),
        completion('homework', THANDI_MEMBER, KID_MEMBER),
      ),
    );
  });

  it('denies claiming somebody else did it', async () => {
    await assertFails(
      setDoc(
        doc(await asUser(THANDI), `${DONE}/bins_${DATE}`),
        completion('bins', SAM_MEMBER, SAM_MEMBER),
      ),
    );
  });

  it('denies filing a completion under an id that is not its own occurrence', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      setDoc(
        doc(db, `${DONE}/laundry_2026-09-20`),
        completion('laundry', THANDI_MEMBER, THANDI_MEMBER),
      ),
    );
    await assertFails(
      setDoc(doc(db, `${DONE}/bins_${DATE}`), completion('laundry', THANDI_MEMBER, THANDI_MEMBER)),
    );
  });

  it('denies dating a completion itself', async () => {
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${DONE}/bins_${DATE}`), {
        ...completion('bins', THANDI_MEMBER, THANDI_MEMBER),
        completedAt: new Date('2000-01-01'),
      }),
    );
  });

  it('is the same write twice, so completing twice changes nothing', async () => {
    const db = await asUser(THANDI);
    const record = completion('bins', THANDI_MEMBER, THANDI_MEMBER);
    await assertSucceeds(setDoc(doc(db, `${DONE}/bins_${DATE}`), record));
    await assertSucceeds(setDoc(doc(db, `${DONE}/bins_${DATE}`), record));
  });

  it('lets any member untick, and denies a stranger everything', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${DONE}/bins_${DATE}`), {
        ...completion('bins', THANDI_MEMBER, THANDI_MEMBER),
        completedAt: new Date(),
      });
    });
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${DONE}/bins_${DATE}`)));

    const stranger = await asUser(STRANGER);
    await assertFails(getDoc(doc(stranger, `${DONE}/bins_${DATE}`)));
    await assertFails(
      setDoc(
        doc(stranger, `${DONE}/bins_${DATE}`),
        completion('bins', THANDI_MEMBER, THANDI_MEMBER),
      ),
    );
  });
});
