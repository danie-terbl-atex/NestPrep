import { deleteField, doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { afterAll, beforeEach, describe, it } from 'vitest';

import {
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  closeRulesEnvironment,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * The welcome tour (welcome-tour ADR-0001): which version of it an account
 * finished or skipped, on `users/{uid}.tour`, shaped like `legalConsent`.
 */
const SAM = 'uid-sam';
const THANDI = 'uid-thandi';

const seen = (version: unknown): Record<string, unknown> => ({
  version,
  seenAt: serverTimestamp(),
});

async function givenAnAccount(tour?: object): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `users/${SAM}`), {
      displayName: 'Sam Parent',
      photoUrl: null,
      householdIds: [],
      activeHouseholdId: null,
      createdAt: new Date(),
      ...(tour === undefined ? {} : { tour }),
    });
  });
}

describe('users/{uid}.tour', () => {
  beforeEach(clearData);
  afterAll(closeRulesEnvironment);

  it('is recorded by the account itself, at the server’s time', async () => {
    await givenAnAccount();
    const db = await asUser(SAM);
    await assertSucceeds(updateDoc(doc(db, `users/${SAM}`), { tour: seen(1) }));
  });

  it('is recorded again for the same version, and for a later one', async () => {
    await givenAnAccount({ version: 1, seenAt: new Date() });
    const db = await asUser(SAM);
    await assertSucceeds(updateDoc(doc(db, `users/${SAM}`), { tour: seen(1) }));
    await assertSucceeds(updateDoc(doc(db, `users/${SAM}`), { tour: seen(2) }));
  });

  it('is never lowered below the version recorded', async () => {
    await givenAnAccount({ version: 2, seenAt: new Date() });
    const db = await asUser(SAM);
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { tour: seen(1) }));
  });

  it('refuses a time the phone chose, a missing field, a bad version or anything extra', async () => {
    await givenAnAccount();
    const db = await asUser(SAM);
    const user = doc(db, `users/${SAM}`);
    await assertFails(updateDoc(user, { tour: { version: 1, seenAt: new Date(2020, 0, 1) } }));
    await assertFails(updateDoc(user, { tour: { version: 1 } }));
    await assertFails(updateDoc(user, { tour: { seenAt: serverTimestamp() } }));
    await assertFails(updateDoc(user, { tour: seen(0) }));
    await assertFails(updateDoc(user, { tour: seen('1') }));
    await assertFails(updateDoc(user, { tour: seen(1.5) }));
    await assertFails(updateDoc(user, { tour: { ...seen(1), step: 4 } }));
    await assertFails(updateDoc(user, { tour: true }));
  });

  it('cannot be taken away again', async () => {
    await givenAnAccount({ version: 1, seenAt: new Date() });
    const db = await asUser(SAM);
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { tour: null }));
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { tour: deleteField() }));
  });

  it('is not somebody else’s to record', async () => {
    await givenAnAccount();
    const db = await asUser(THANDI);
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { tour: seen(1) }));
  });

  it('cannot ride in on a new account, which is made without it', async () => {
    const db = await asUser(SAM);
    const account = {
      displayName: 'Sam Parent',
      photoUrl: null,
      householdIds: [],
      activeHouseholdId: null,
      createdAt: serverTimestamp(),
      lastSignedInAt: serverTimestamp(),
    };
    await assertFails(setDoc(doc(db, `users/${SAM}`), { ...account, tour: seen(1) }));
    await assertSucceeds(setDoc(doc(db, `users/${SAM}`), account));
  });
});
