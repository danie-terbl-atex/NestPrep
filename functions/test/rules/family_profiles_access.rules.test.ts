import { doc, getDoc, setDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  CLEO,
  HEALTH,
  KID,
  KID_TABLET,
  NOMSA,
  PROFILES,
  SCHOOLS,
  givenTheKidsDetails,
  givenTheParkers,
  merge,
} from './family_fixture';
import { asKid, asUser, assertFails, assertSucceeds, clearData } from './rules_harness';

/**
 * Who reads a family profile and its medication is the household's grant
 * (family-profiles ADR-0002, household ADR-0003): `familyProfiles` for the
 * profile — allergies included — and `medical` for the medicine, each at
 * `own` only for the caller's own member. A kid device holds its kid profile's
 * grant (accounts ADR-0004). A person with a login always reads and keeps
 * their own, whatever the grant.
 */

const tablet = (): ReturnType<typeof asKid> =>
  asKid(KID_TABLET, { householdId: 'h1', memberId: KID });

beforeEach(async () => {
  await clearData();
  await givenTheParkers();
  await givenTheKidsDetails();
});

describe('a carer on the carer defaults', () => {
  it('reads a child’s profile and their medication', async () => {
    const db = await asUser(NOMSA);
    await assertSucceeds(getDoc(doc(db, `${PROFILES}/${KID}`)));
    await assertSucceeds(getDoc(doc(db, `${HEALTH}/${KID}`)));
    await assertSucceeds(getDoc(doc(db, `${SCHOOLS}/oakwood`)));
  });

  it('and changes neither, because view is not edit', async () => {
    const db = await asUser(NOMSA);
    await assertFails(setDoc(doc(db, `${PROFILES}/${KID}`), { likes: ['Sweets'] }, merge));
    await assertFails(setDoc(doc(db, `${HEALTH}/${KID}`), { medications: {} }, merge));
  });
});

describe('a cleaner the household gave neither area', () => {
  it('reads no child’s profile, medication or school', async () => {
    const db = await asUser(CLEO);
    await assertFails(getDoc(doc(db, `${PROFILES}/${KID}`)));
    await assertFails(getDoc(doc(db, `${HEALTH}/${KID}`)));
    await assertFails(getDoc(doc(db, `${SCHOOLS}/oakwood`)));
  });

  it('but reads and keeps their own, which is about them', async () => {
    const db = await asUser(CLEO);
    await assertSucceeds(setDoc(doc(db, `${PROFILES}/m-cleo`), { shoeSize: 'UK 6' }, merge));
    await assertSucceeds(getDoc(doc(db, `${PROFILES}/m-cleo`)));
    await assertSucceeds(setDoc(doc(db, `${HEALTH}/m-cleo`), { medications: {} }, merge));
    await assertSucceeds(getDoc(doc(db, `${HEALTH}/m-cleo`)));
  });
});

describe('a kid’s tablet, on the kid defaults', () => {
  it('reads its own profile — its allergies — and its school', async () => {
    const db = await tablet();
    await assertSucceeds(getDoc(doc(db, `${PROFILES}/${KID}`)));
    await assertSucceeds(getDoc(doc(db, `${SCHOOLS}/oakwood`)));
  });

  it('not a grown-up’s profile, and not its own medication', async () => {
    const db = await tablet();
    await assertFails(getDoc(doc(db, `${PROFILES}/m-mia`)));
    await assertFails(getDoc(doc(db, `${HEALTH}/${KID}`)));
  });

  it('and changes nothing in its own profile — a parent does that', async () => {
    const db = await tablet();
    await assertFails(setDoc(doc(db, `${PROFILES}/${KID}`), { likes: ['Sweets'] }, merge));
  });
});
