import { deleteDoc, doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { DATE, HOME, PEOPLE, RECORDS, givenAHouseholdOfEveryRole } from './access_fixture';
import { asUser, assertFails, assertSucceeds, clearData } from './rules_harness';

/**
 * What each role may **write** in a household's areas (household ADR-0003):
 * `edit` does what family does, `view` writes nothing, and `own` acts only on
 * what is theirs. Reads are in `access_reads.rules.test.ts`; membership, the
 * grant itself and the invite step in `access_membership.rules.test.ts`.
 */
function grocery(addedBy: string): Record<string, unknown> {
  return {
    name: 'Eggs',
    quantity: null,
    addedBy,
    addedAt: serverTimestamp(),
    boughtAt: null,
    boughtBy: null,
  };
}

function event(createdBy: string): Record<string, unknown> {
  return {
    title: 'Dentist',
    note: null,
    date: DATE,
    startMinute: 600,
    endMinute: 660,
    recurrence: null,
    memberIds: [],
    createdBy,
    createdAt: serverTimestamp(),
  };
}

function completion(taskId: string, by: string, forMember: string): Record<string, unknown> {
  return {
    taskId,
    occurrenceDate: DATE,
    completedBy: by,
    completedFor: forMember,
    completedAt: serverTimestamp(),
  };
}

describe('writing, by level', () => {
  beforeEach(async () => {
    await clearData();
    await givenAHouseholdOfEveryRole();
  });

  it('lets family add to every area, the old `member` included', async () => {
    for (const person of [PEOPLE.parent, PEOPLE.legacyMember]) {
      const db = await asUser(person.uid);
      await assertSucceeds(
        setDoc(doc(db, `${HOME}/groceryItems/${person.member}`), grocery(person.member)),
      );
      await assertSucceeds(
        setDoc(doc(db, `${HOME}/events/${person.member}`), event(person.member)),
      );
    }
  });

  it('lets a helper with groceries at edit add and tick, as the list has always allowed', async () => {
    // The carer's defaults hold groceries at view; the helper defaults at edit.
    const helper = await asUser(PEOPLE.legacyHelper.uid);
    await assertSucceeds(
      setDoc(doc(helper, `${HOME}/groceryItems/eggs`), grocery(PEOPLE.legacyHelper.member)),
    );
    await assertSucceeds(
      updateDoc(doc(helper, RECORDS.groceries[0]), {
        boughtAt: serverTimestamp(),
        boughtBy: PEOPLE.legacyHelper.member,
      }),
    );
  });

  it('refuses a view-only helper every write: add, tick, plan, schedule', async () => {
    const db = await asUser(PEOPLE.viewer.uid);
    const me = PEOPLE.viewer.member;
    await assertFails(setDoc(doc(db, `${HOME}/groceryItems/eggs`), grocery(me)));
    await assertFails(
      updateDoc(doc(db, RECORDS.groceries[0]), { boughtAt: serverTimestamp(), boughtBy: me }),
    );
    await assertFails(setDoc(doc(db, `${HOME}/events/dentist`), event(me)));
    await assertFails(setDoc(doc(db, `${HOME}/mealPlans/2026-10-05`), { slots: {} }));
    await assertFails(
      setDoc(doc(db, `${HOME}/eventExceptions/swim_2026-10-06`), {
        eventId: 'swim',
        occurrenceDate: '2026-10-06',
        skippedBy: me,
        skippedAt: serverTimestamp(),
      }),
    );
  });

  it('refuses a carer, whose groceries are view, the add a helper may make', async () => {
    const db = await asUser(PEOPLE.carer.uid);
    await assertFails(setDoc(doc(db, `${HOME}/groceryItems/eggs`), grocery(PEOPLE.carer.member)));
  });

  it('refuses a helper whose documents are none a document, and a delete of one', async () => {
    const db = await asUser(PEOPLE.cleaner.uid);
    await assertFails(
      setDoc(doc(db, `${HOME}/documents/payslip`), {
        folderId: 'school',
        name: 'Payslip',
        contentType: 'application/pdf',
        sizeBytes: 10,
        uploadedBy: PEOPLE.cleaner.member,
        uploadedAt: serverTimestamp(),
      }),
    );
    await assertFails(deleteDoc(doc(db, RECORDS.documents[1])));
  });
});

describe('`own`: acting on what is theirs', () => {
  beforeEach(async () => {
    await clearData();
    await givenAHouseholdOfEveryRole();
  });

  it('lets a kid tick off their own chore', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    const me = PEOPLE.kid.member;
    await assertSucceeds(
      setDoc(doc(db, `${HOME}/taskCompletions/homework_${DATE}`), completion('homework', me, me)),
    );
  });

  it('refuses a kid completing a chore that is for anyone — they cannot even see it', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    const me = PEOPLE.kid.member;
    await assertFails(
      setDoc(doc(db, `${HOME}/taskCompletions/bins_2026-09-30`), {
        ...completion('bins', me, me),
        occurrenceDate: '2026-09-30',
      }),
    );
  });

  it('refuses a kid completing somebody else’s chore, in either name', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    await assertFails(
      setDoc(
        doc(db, `${HOME}/taskCompletions/tax_${DATE}`),
        completion('tax', PEOPLE.kid.member, PEOPLE.admin.member),
      ),
    );
    await assertFails(
      setDoc(
        doc(db, `${HOME}/taskCompletions/tax_${DATE}`),
        completion('tax', PEOPLE.kid.member, PEOPLE.kid.member),
      ),
    );
  });

  it('lets a kid undo their own tick and nobody else’s', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    await assertSucceeds(deleteDoc(doc(db, `${HOME}/taskCompletions/homework_2026-09-28`)));
    await assertFails(deleteDoc(doc(db, RECORDS.todos[2])));
  });

  it('refuses a kid creating a task at all', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    await assertFails(
      setDoc(doc(db, `${HOME}/tasks/new`), {
        title: 'Buy a pony',
        note: null,
        dueDate: DATE,
        recurrence: null,
        assigneeIds: [PEOPLE.kid.member],
        createdBy: PEOPLE.kid.member,
        routineId: null,
        createdAt: serverTimestamp(),
      }),
    );
  });
});
