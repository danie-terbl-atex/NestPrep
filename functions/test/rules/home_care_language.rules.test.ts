import { deleteDoc, doc, getDoc, serverTimestamp, setDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  HOME,
  KID_DEVICE,
  PEOPLE,
  givenAHouseholdOfEveryRole,
  type Person,
} from './access_fixture';
import {
  asKid,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * The helper's language and the translations made for it (home-care
 * ADR-0006). She sets her own; family sets anybody's; the translations and
 * what they cost are the Function's to write.
 */

const as = (person: Person): Promise<Firestore> => asUser(PEOPLE[person].uid);

const tablet = (): Promise<Firestore> =>
  asKid(KID_DEVICE, { householdId: 'h-access', memberId: PEOPLE.kid.member });

const CLEANER = PEOPLE.cleaner.member;
const profile = (memberId: string): string => `${HOME}/homeCareHelpers/${memberId}`;
const TRANSLATION = `${HOME}/homeCareTranslations/abc_zu`;
const USAGE = `${HOME}/homeCareTranslationUsage/2026-09`;

function language(code: string, by: string): Record<string, unknown> {
  return { language: code, updatedBy: by, updatedAt: serverTimestamp() };
}

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await givenData(async (db) => {
    await setDoc(doc(db, profile('m-unclaimed')), {
      language: 'ny',
      updatedBy: PEOPLE.admin.member,
      updatedAt: new Date(),
    });
    await setDoc(doc(db, TRANSLATION), {
      language: 'zu',
      text: 'Vula ifasitela',
      engine: 'cloudTranslation',
      createdAt: new Date(),
    });
    await setDoc(doc(db, USAGE), { characters: 120 });
  });
});

describe('a helper’s language', () => {
  it('lets the cleaner set and read her own', async () => {
    const db = await as('cleaner');
    await assertSucceeds(setDoc(doc(db, profile(CLEANER)), language('zu', CLEANER)));
    await assertSucceeds(getDoc(doc(db, profile(CLEANER))));
  });

  it('lets the look-only helper set her own and read everybody’s', async () => {
    const db = await as('viewer');
    const vera = PEOPLE.viewer.member;
    await assertSucceeds(setDoc(doc(db, profile(vera)), language('st', vera)));
    await assertSucceeds(getDoc(doc(db, profile('m-unclaimed'))));
  });

  it('lets family set a helper’s language for her', async () => {
    const db = await as('parent');
    await assertSucceeds(
      setDoc(doc(db, profile('m-unclaimed')), language('xh', PEOPLE.parent.member)),
    );
    await assertSucceeds(deleteDoc(doc(db, profile('m-unclaimed'))));
  });

  it('denies a helper setting or reading somebody else’s', async () => {
    const db = await as('cleaner');
    await assertFails(setDoc(doc(db, profile('m-unclaimed')), language('zu', CLEANER)));
    await assertFails(getDoc(doc(db, profile('m-unclaimed'))));
    await assertFails(
      setDoc(doc(await as('viewer'), profile(CLEANER)), language('zu', PEOPLE.viewer.member)),
    );
  });

  it('refuses a language the app does not offer, and a profile for nobody', async () => {
    const db = await as('admin');
    const by = PEOPLE.admin.member;
    await assertFails(setDoc(doc(db, profile(CLEANER)), language('fr', by)));
    await assertFails(setDoc(doc(db, profile('m-nobody')), language('zu', by)));
  });

  it('refuses a change in somebody else’s name, or at the client’s time', async () => {
    const db = await as('cleaner');
    await assertFails(setDoc(doc(db, profile(CLEANER)), language('zu', PEOPLE.admin.member)));
    await assertFails(
      setDoc(doc(db, profile(CLEANER)), {
        language: 'zu',
        updatedBy: CLEANER,
        updatedAt: new Date(0),
      }),
    );
  });

  it('denies the carer, the kid and the tablet', async () => {
    for (const person of ['carer', 'kid'] as Person[]) {
      const db = await as(person);
      const own = PEOPLE[person].member;
      await assertFails(setDoc(doc(db, profile(own)), language('zu', own)));
      await assertFails(getDoc(doc(db, profile('m-unclaimed'))));
    }
    await assertFails(getDoc(doc(await tablet(), profile('m-unclaimed'))));
  });

  it('lets only family remove one', async () => {
    await assertFails(deleteDoc(doc(await as('viewer'), profile('m-unclaimed'))));
  });
});

describe('the translations and their cost', () => {
  it('lets anybody who sees home care read a translation', async () => {
    for (const person of ['admin', 'cleaner', 'viewer', 'legacyHelper'] as Person[]) {
      await assertSucceeds(getDoc(doc(await as(person), TRANSLATION)));
    }
  });

  it('denies a translation to whoever has no home care', async () => {
    await assertFails(getDoc(doc(await as('carer'), TRANSLATION)));
    await assertFails(getDoc(doc(await tablet(), TRANSLATION)));
  });

  it('lets nobody write a translation, not even an admin', async () => {
    const db = await as('admin');
    await assertFails(
      setDoc(doc(db, `${HOME}/homeCareTranslations/new_zu`), {
        language: 'zu',
        text: 'Hlanza',
        engine: 'cloudTranslation',
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(deleteDoc(doc(db, TRANSLATION)));
  });

  it('keeps the cost ledger from every client', async () => {
    const db = await as('admin');
    await assertFails(getDoc(doc(db, USAGE)));
    await assertFails(setDoc(doc(db, USAGE), { characters: 0 }));
  });
});
