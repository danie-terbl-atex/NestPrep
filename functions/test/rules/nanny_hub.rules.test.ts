import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { HOME, HOUSEHOLD, KID_DEVICE, PEOPLE, type Person } from './access_fixture';
import { CARER, CHILD, PATHS, card, contact, givenAHubOfEveryRole } from './nanny_fixture';
import {
  asKid,
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  type Firestore,
} from './rules_harness';

/**
 * Who reads the nanny hub and who writes it: the household's `nannyHub` grant
 * and nothing else (household ADR-0003, nanny-hub ADR-0003). `view` reads,
 * `edit` writes, `none` is not there at all. Shifts and the handover log are
 * in `nanny_shifts.rules.test.ts`.
 */

const READERS: Person[] = ['admin', 'parent', 'legacyMember', 'carer', 'viewer', 'legacyHelper'];
const NOT_READERS: Person[] = ['kid', 'cleaner'];
const EVERY_RECORD = Object.values(PATHS);

const merge = { merge: true } as const;

beforeEach(async () => {
  await clearData();
  await givenAHubOfEveryRole();
});

describe('reading the hub', () => {
  for (const person of READERS) {
    it(`lets ${person} read every record in it`, async () => {
      const db = await asUser(PEOPLE[person].uid);
      await Promise.all(EVERY_RECORD.map((path) => assertSucceeds(getDoc(doc(db, path)))));
      await assertSucceeds(getDocs(collection(db, `${HOME}/nannyContacts`)));
    });
  }

  for (const person of NOT_READERS) {
    it(`refuses ${person}, whose grant holds no hub, every record`, async () => {
      const db = await asUser(PEOPLE[person].uid);
      await Promise.all(EVERY_RECORD.map((path) => assertFails(getDoc(doc(db, path)))));
      await assertFails(getDocs(collection(db, `${HOME}/nannyGuide`)));
    });
  }

  it('refuses the kid’s tablet, which holds the kid’s grant', async () => {
    const db = await asKid(KID_DEVICE, { householdId: HOUSEHOLD, memberId: CHILD });
    for (const path of EVERY_RECORD) await assertFails(getDoc(doc(db, path)));
  });

  it('refuses a stranger and somebody signed out', async () => {
    for (const db of [await asUser('uid-stranger'), await asSignedOut()]) {
      await assertFails(getDoc(doc(db, PATHS.card)));
      await assertFails(getDoc(doc(db, PATHS.sheet)));
    }
  });
});

describe('a child’s card', () => {
  it('is written by the carer, whose hub is edit, a section at a time', async () => {
    const db = await asUser(CARER.uid);
    await assertSucceeds(setDoc(doc(db, PATHS.card), card(CARER.member), merge));
  });

  it('and by a parent, for a child who has no card yet', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(
      setDoc(doc(db, `${HOME}/nannyChildCards/${PEOPLE.kid.member}`), card(PEOPLE.parent.member)),
    );
  });

  it('never by a helper at view, the cleaner or the kid’s tablet', async () => {
    for (const person of ['viewer', 'cleaner'] as const) {
      const db = await asUser(PEOPLE[person].uid);
      await assertFails(setDoc(doc(db, PATHS.card), card(PEOPLE[person].member), merge));
    }
    const tablet = await asKid(KID_DEVICE, { householdId: HOUSEHOLD, memberId: CHILD });
    await assertFails(setDoc(doc(tablet, PATHS.card), card(CHILD), merge));
  });

  it('is refused for somebody who is not in the household', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    await assertFails(
      setDoc(doc(db, `${HOME}/nannyChildCards/m-nobody`), card(PEOPLE.parent.member)),
    );
  });

  it('is refused in somebody else’s name, or with a time the client chose', async () => {
    const db = await asUser(CARER.uid);
    await assertFails(setDoc(doc(db, PATHS.card), card(PEOPLE.admin.member), merge));
    await assertFails(
      setDoc(doc(db, PATHS.card), { ...card(CARER.member), updatedAt: new Date() }, merge),
    );
  });

  it('is refused past its limits, or with a field it does not have', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    const by = PEOPLE.parent.member;
    const thirteen = Array.from({ length: 13 }, (_, index) => ({ label: `Step ${String(index)}` }));
    await assertFails(setDoc(doc(db, PATHS.card), { ...card(by), routines: thirteen }, merge));
    await assertFails(
      setDoc(doc(db, PATHS.card), { ...card(by), settling: 'x'.repeat(601) }, merge),
    );
    await assertFails(setDoc(doc(db, PATHS.card), { ...card(by), photoId: '../x' }, merge));
    await assertFails(setDoc(doc(db, PATHS.card), { ...card(by), alarmCode: '1234' }, merge));
  });

  it('is removed by whoever may write the hub, and nobody else', async () => {
    await assertFails(deleteDoc(doc(await asUser(PEOPLE.viewer.uid), PATHS.card)));
    await assertSucceeds(deleteDoc(doc(await asUser(CARER.uid), PATHS.card)));
  });
});

describe('the emergency sheet', () => {
  it('takes a contact with a number that can be dialled', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(
      setDoc(doc(db, `${HOME}/nannyContacts/doctor`), contact(PEOPLE.parent.member)),
    );
  });

  it('refuses a number with letters in it, a kind it does not know, or no name', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    const by = PEOPLE.parent.member;
    const path = `${HOME}/nannyContacts/bad`;
    await assertFails(setDoc(doc(db, path), contact(by, { phone: 'call me' })));
    await assertFails(setDoc(doc(db, path), contact(by, { kind: 'plumber' })));
    await assertFails(setDoc(doc(db, path), contact(by, { name: '' })));
  });

  it('lets an edit change the number and nothing about who added it', async () => {
    const db = await asUser(CARER.uid);
    await assertSucceeds(updateDoc(doc(db, PATHS.contact), { phone: '082 555 0199' }));
    await assertFails(updateDoc(doc(db, PATHS.contact), { createdBy: CARER.member }));
  });

  it('refuses a helper at view any change', async () => {
    const db = await asUser(PEOPLE.viewer.uid);
    await assertFails(updateDoc(doc(db, PATHS.contact), { phone: '082 555 0199' }));
    await assertFails(deleteDoc(doc(db, PATHS.contact)));
  });

  it('keeps the home’s facts in one document called sheet, and nowhere else', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    const sheet = {
      address: '12 Acacia Lane, Parkhurst',
      medicalAidScheme: 'Discovery',
      medicalAidPlan: 'Classic',
      medicalAidNumber: '123456789',
      updatedBy: PEOPLE.parent.member,
      updatedAt: serverTimestamp(),
    };
    await assertSucceeds(setDoc(doc(db, PATHS.sheet), sheet));
    await assertFails(setDoc(doc(db, PATHS.sheet), { ...sheet, updatedAt: new Date() }));
    await assertFails(setDoc(doc(db, `${HOME}/nannyHome/other`), sheet));
    await assertFails(setDoc(doc(db, PATHS.sheet), { ...sheet, alarmCode: '1234' }));
    await assertFails(deleteDoc(doc(db, PATHS.sheet)));
  });
});

describe('the house guide, the house rules and the checklists', () => {
  async function parent(): Promise<Firestore> {
    return asUser(PEOPLE.parent.uid);
  }

  it('lets a spot carry a photo by its id, and refuses anything shaped like a path', async () => {
    const db = await parent();
    await assertSucceeds(updateDoc(doc(db, PATHS.spot), { photoId: 'Abc123_photo-01' }));
    await assertFails(updateDoc(doc(db, PATHS.spot), { photoId: 'households/h/other' }));
    await assertFails(updateDoc(doc(db, PATHS.spot), { title: '' }));
  });

  it('keeps a house rule short, and lets the carer change one', async () => {
    await assertSucceeds(updateDoc(doc(await asUser(CARER.uid), PATHS.rule), { text: 'Bed by 8' }));
    await assertFails(updateDoc(doc(await parent(), PATHS.rule), { text: 'x'.repeat(301) }));
    await assertFails(updateDoc(doc(await asUser(PEOPLE.cleaner.uid), PATHS.rule), { text: 'No' }));
  });

  it('has a checklist for each of the five parts of a shift, and no other', async () => {
    const db = await parent();
    const list = { items: [], updatedBy: PEOPLE.parent.member, updatedAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db, `${HOME}/nannyChecklists/arrival`), list));
    await assertFails(setDoc(doc(db, `${HOME}/nannyChecklists/midnight`), list));
  });

  it('keeps a checklist to twenty items', async () => {
    const db = await parent();
    const items = Array.from({ length: 21 }, (_, index) => ({
      id: `i${String(index)}`,
      text: 'x',
    }));
    await assertFails(
      setDoc(doc(db, PATHS.checklist), {
        items,
        updatedBy: PEOPLE.parent.member,
        updatedAt: serverTimestamp(),
      }),
    );
  });
});
