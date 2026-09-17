import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { afterAll, beforeEach, describe, it } from 'vitest';

import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  closeRulesEnvironment,
  givenData,
} from './rules_harness';

const SAM = 'uid-sam';
const ALEX = 'uid-alex';

const newAccount = {
  displayName: 'Sam Parent',
  photoUrl: null,
  householdIds: [],
  activeHouseholdId: null,
  createdAt: serverTimestamp(),
  lastSignedInAt: serverTimestamp(),
};

describe('users/{uid}', () => {
  beforeEach(clearData);
  afterAll(closeRulesEnvironment);

  it('lets an account create its own document, empty of households', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `users/${SAM}`), newAccount));
    await assertSucceeds(getDoc(doc(db, `users/${SAM}`)));
  });

  it('denies creating a document for somebody else', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `users/${ALEX}`), newAccount));
  });

  it('denies reading somebody else"s account', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `users/${ALEX}`), { ...newAccount, createdAt: new Date() });
    });
    const db = await asUser(SAM);
    await assertFails(getDoc(doc(db, `users/${ALEX}`)));
  });

  it('denies a signed-out caller entirely', async () => {
    const db = await asSignedOut();
    await assertFails(getDoc(doc(db, `users/${SAM}`)));
    await assertFails(setDoc(doc(db, `users/${SAM}`), newAccount));
  });

  it('denies an account that hands itself a household on creation', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `users/${SAM}`), { ...newAccount, householdIds: ['h1'] }));
    await assertFails(setDoc(doc(db, `users/${SAM}`), { ...newAccount, activeHouseholdId: 'h1' }));
  });

  it('denies dating its own creation instead of letting the server do it', async () => {
    const db = await asUser(SAM);
    await assertFails(
      setDoc(doc(db, `users/${SAM}`), { ...newAccount, createdAt: new Date('2000-01-01') }),
    );
  });

  it('denies a field the rule does not name', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `users/${SAM}`), { ...newAccount, isAdmin: true }));
  });

  it('lets an account refresh what Google says about it', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `users/${SAM}`), { ...newAccount, createdAt: new Date() });
    });
    const db = await asUser(SAM);
    await assertSucceeds(
      updateDoc(doc(db, `users/${SAM}`), {
        displayName: 'Samantha Parent',
        photoUrl: 'https://example.test/p.png',
        lastSignedInAt: serverTimestamp(),
      }),
    );
  });

  it('denies an account granting itself a household', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `users/${SAM}`), { ...newAccount, createdAt: new Date() });
    });
    const db = await asUser(SAM);
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { householdIds: ['h1'] }));
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { activeHouseholdId: 'h1' }));
  });

  it('lets an account switch to a household it already belongs to, and only that one', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `users/${SAM}`), {
        ...newAccount,
        householdIds: ['h1', 'h2'],
        activeHouseholdId: 'h1',
        createdAt: new Date(),
      });
    });
    const db = await asUser(SAM);
    await assertSucceeds(updateDoc(doc(db, `users/${SAM}`), { activeHouseholdId: 'h2' }));
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { activeHouseholdId: 'h3' }));
  });

  it('denies backdating the last sign-in', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `users/${SAM}`), { ...newAccount, createdAt: new Date() });
    });
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(doc(db, `users/${SAM}`), { lastSignedInAt: new Date('2000-01-01') }),
    );
  });

  it('denies deleting an account, and denies rewriting when it was created', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `users/${SAM}`), { ...newAccount, createdAt: new Date() });
    });
    const db = await asUser(SAM);
    await assertFails(deleteDoc(doc(db, `users/${SAM}`)));
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { createdAt: new Date() }));
  });
});

describe('invites/{code}', () => {
  beforeEach(clearData);

  it('denies every client, member or not — only Functions touch invites', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, 'invites/ABCD2345'), {
        householdId: 'h1',
        memberId: 'm1',
        redeemedBy: null,
      });
    });
    const db = await asUser(SAM);
    await assertFails(getDoc(doc(db, 'invites/ABCD2345')));
    await assertFails(setDoc(doc(db, 'invites/NEWCODE9'), { householdId: 'h1' }));
    await assertFails(updateDoc(doc(db, 'invites/ABCD2345'), { redeemedBy: SAM }));
  });
});
