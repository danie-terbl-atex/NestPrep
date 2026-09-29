import { doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
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
 * Consent (accounts ADR-0005): the versions an account agreed to, and a
 * parent's consent on every child's profile a client writes.
 */
const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const HOME = 'households/h1';

const consent = (termsVersion: number, privacyVersion: number): Record<string, unknown> => ({
  termsVersion,
  privacyVersion,
  acceptedAt: serverTimestamp(),
});

async function givenAnAccount(legalConsent?: object): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `users/${SAM}`), {
      displayName: 'Sam Parent',
      photoUrl: null,
      householdIds: [],
      activeHouseholdId: null,
      createdAt: new Date(),
      ...(legalConsent === undefined ? {} : { legalConsent }),
    });
  });
}

describe('users/{uid}.legalConsent', () => {
  beforeEach(clearData);
  afterAll(closeRulesEnvironment);

  it('is recorded by the account itself, at the server’s time', async () => {
    await givenAnAccount();
    const db = await asUser(SAM);
    await assertSucceeds(updateDoc(doc(db, `users/${SAM}`), { legalConsent: consent(1, 1) }));
  });

  it('rises when a document changes, and is agreed again', async () => {
    await givenAnAccount({ termsVersion: 1, privacyVersion: 1, acceptedAt: new Date() });
    const db = await asUser(SAM);
    await assertSucceeds(updateDoc(doc(db, `users/${SAM}`), { legalConsent: consent(1, 2) }));
  });

  it('is never lowered below what was agreed', async () => {
    await givenAnAccount({ termsVersion: 2, privacyVersion: 2, acceptedAt: new Date() });
    const db = await asUser(SAM);
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { legalConsent: consent(1, 2) }));
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { legalConsent: consent(2, 1) }));
  });

  it('refuses a time the phone chose, a missing version, or anything extra', async () => {
    await givenAnAccount();
    const db = await asUser(SAM);
    const user = doc(db, `users/${SAM}`);
    await assertFails(
      updateDoc(user, {
        legalConsent: { termsVersion: 1, privacyVersion: 1, acceptedAt: new Date(2020, 0, 1) },
      }),
    );
    await assertFails(
      updateDoc(user, { legalConsent: { termsVersion: 1, acceptedAt: serverTimestamp() } }),
    );
    await assertFails(updateDoc(user, { legalConsent: { ...consent(1, 1), isAdult: true } }));
    await assertFails(updateDoc(user, { legalConsent: consent(0, 1) }));
    await assertFails(updateDoc(user, { legalConsent: { ...consent(1, 1), termsVersion: '1' } }));
    await assertFails(updateDoc(user, { legalConsent: 'yes' }));
  });

  it('is not somebody else’s to give', async () => {
    await givenAnAccount();
    const db = await asUser(THANDI);
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { legalConsent: consent(1, 1) }));
  });

  it('cannot be taken away again', async () => {
    await givenAnAccount({ termsVersion: 1, privacyVersion: 1, acceptedAt: new Date() });
    const db = await asUser(SAM);
    await assertFails(updateDoc(doc(db, `users/${SAM}`), { legalConsent: null }));
  });
});

/** Sam, an admin with a profile; Thandi, a helper with one; an adult nobody claimed. */
async function givenAHousehold(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, HOME), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
      createdBy: SAM,
      createdAt: new Date(),
    });
    const profiles: [string, string, string | null][] = [
      ['m-sam', 'admin', SAM],
      ['m-thandi', 'helper', THANDI],
      ['m-gran', 'parent', null],
      ['m-old-kid', 'kid', null],
    ];
    for (const [id, role, claimedBy] of profiles) {
      await setDoc(doc(db, `${HOME}/members/${id}`), {
        displayName: id,
        color: 'sky',
        role,
        claimedBy,
        createdAt: new Date(),
      });
    }
  });
}

const given = (byMemberId = 'm-sam'): Record<string, unknown> => ({
  byMemberId,
  version: 1,
  at: serverTimestamp(),
});

const newKid = {
  displayName: 'Lwazi',
  color: 'sky',
  role: 'kid',
  birthday: null,
  claimedBy: null,
  createdAt: serverTimestamp(),
};

describe('households/{h}/members — a parent’s consent on a child', () => {
  beforeEach(async () => {
    await clearData();
    await givenAHousehold();
  });

  it('a kid is made with the consent of the admin making it', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      setDoc(doc(db, `${HOME}/members/m-lwazi`), { ...newKid, guardianConsent: given() }),
    );
  });

  it('a kid without consent is refused', async () => {
    const db = await asUser(SAM);
    await assertFails(setDoc(doc(db, `${HOME}/members/m-lwazi`), newKid));
    await assertFails(
      setDoc(doc(db, `${HOME}/members/m-lwazi`), { ...newKid, guardianConsent: null }),
    );
  });

  it('consent is given by the writer, never in somebody else’s name', async () => {
    const db = await asUser(SAM);
    for (const byMemberId of ['m-thandi', 'm-gran', 'm-nobody']) {
      await assertFails(
        setDoc(doc(db, `${HOME}/members/m-lwazi`), {
          ...newKid,
          guardianConsent: given(byMemberId),
        }),
      );
    }
  });

  it('consent has its shape and the server’s time', async () => {
    const db = await asUser(SAM);
    const kid = doc(db, `${HOME}/members/m-lwazi`);
    await assertFails(
      setDoc(kid, { ...newKid, guardianConsent: { ...given(), at: new Date(2020, 0, 1) } }),
    );
    await assertFails(setDoc(kid, { ...newKid, guardianConsent: { ...given(), version: 0 } }));
    await assertFails(setDoc(kid, { ...newKid, guardianConsent: { ...given(), extra: true } }));
    await assertFails(setDoc(kid, { ...newKid, guardianConsent: { byMemberId: 'm-sam' } }));
  });

  it('an adult carries none', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `${HOME}/members/m-aunt`), { ...newKid, role: 'parent' }));
    await assertFails(
      setDoc(doc(db, `${HOME}/members/m-uncle`), {
        ...newKid,
        role: 'parent',
        guardianConsent: given(),
      }),
    );
  });

  it('an adult moved to kid needs it, and may be given it then', async () => {
    const db = await asUser(SAM);
    const gran = doc(db, `${HOME}/members/m-gran`);
    await assertFails(updateDoc(gran, { role: 'kid' }));
    await assertSucceeds(updateDoc(gran, { role: 'kid', guardianConsent: given() }));
  });

  it('once given, it is neither rewritten nor taken away', async () => {
    const db = await asUser(SAM);
    const kid = doc(db, `${HOME}/members/m-lwazi`);
    await assertSucceeds(setDoc(kid, { ...newKid, guardianConsent: given() }));
    await assertFails(updateDoc(kid, { guardianConsent: null }));
    await assertFails(updateDoc(kid, { guardianConsent: { ...given(), version: 2 } }));
    await assertSucceeds(updateDoc(kid, { displayName: 'Lwazi P' }));
  });

  it('a kid made before consent keeps working, and can be given it', async () => {
    const db = await asUser(SAM);
    const old = doc(db, `${HOME}/members/m-old-kid`);
    await assertSucceeds(updateDoc(old, { displayName: 'Still a kid' }));
    await assertSucceeds(updateDoc(old, { guardianConsent: given() }));
  });

  it('a helper can make no kid, consent or not', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      setDoc(doc(db, `${HOME}/members/m-lwazi`), {
        ...newKid,
        guardianConsent: given('m-thandi'),
      }),
    );
  });
});
