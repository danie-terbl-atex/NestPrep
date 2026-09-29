import { doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { ROLE_DEFAULTS } from '../../src/household/access';
import { HOME, PEOPLE, givenAHouseholdOfEveryRole } from './access_fixture';
import { asUser, assertFails, assertSucceeds, clearData } from './rules_harness';

/**
 * Who may change who is in a household and what they may see (household
 * ADR-0003): nobody but an admin, a grant only in a shape the rules know, a
 * claimed member's grant only through `setMemberAccess`, and the invite step
 * closed by an admin and never reopened.
 */
describe('a kid cannot change membership', () => {
  beforeEach(async () => {
    await clearData();
    await givenAHouseholdOfEveryRole();
  });

  it('cannot add a profile, re-role one, or rename the household', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    await assertFails(
      setDoc(doc(db, `${HOME}/members/m-new`), {
        displayName: 'Friend',
        color: 'mint',
        role: 'parent',
        claimedBy: null,
        createdAt: serverTimestamp(),
      }),
    );
    await assertFails(updateDoc(doc(db, `${HOME}/members/m-unclaimed`), { role: 'admin' }));
    await assertFails(updateDoc(doc(db, HOME), { name: 'Kid Town' }));
  });

  it('cannot give itself a grant, nor write the household’s access map', async () => {
    const db = await asUser(PEOPLE.kid.uid);
    await assertFails(
      updateDoc(doc(db, `${HOME}/members/${PEOPLE.kid.member}`), { access: ROLE_DEFAULTS.carer }),
    );
    await assertFails(updateDoc(doc(db, HOME), { [`access.${PEOPLE.kid.uid}.documents`]: 'edit' }));
    await assertFails(updateDoc(doc(db, HOME), { [`members.${PEOPLE.kid.uid}`]: 'admin' }));
  });
});

describe('a grant on a profile', () => {
  beforeEach(async () => {
    await clearData();
    await givenAHouseholdOfEveryRole();
  });

  const newHelper = {
    displayName: 'Grace',
    color: 'mint',
    role: 'helper',
    birthday: null,
    claimedBy: null,
    createdAt: serverTimestamp(),
  };

  it('is written by an admin with a new kid, helper or carer', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertSucceeds(
      setDoc(doc(db, `${HOME}/members/m-grace`), { ...newHelper, access: ROLE_DEFAULTS.helper }),
    );
    await assertSucceeds(
      setDoc(doc(db, `${HOME}/members/m-kiddo`), {
        ...newHelper,
        role: 'kid',
        access: ROLE_DEFAULTS.kid,
        // A child's profile carries a parent's consent (accounts ADR-0005).
        guardianConsent: { byMemberId: PEOPLE.admin.member, version: 1, at: serverTimestamp() },
      }),
    );
  });

  it('is refused when it names an area or a level nobody has heard of', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertFails(
      setDoc(doc(db, `${HOME}/members/m-grace`), { ...newHelper, access: { garage: 'edit' } }),
    );
    await assertFails(
      setDoc(doc(db, `${HOME}/members/m-grace`), { ...newHelper, access: { calendar: 'admin' } }),
    );
    await assertFails(setDoc(doc(db, `${HOME}/members/m-grace`), { ...newHelper, access: 'edit' }));
  });

  it('is refused from a parent, who is family but does not manage people', async () => {
    const db = await asUser(PEOPLE.parent.uid);
    await assertFails(
      setDoc(doc(db, `${HOME}/members/m-grace`), { ...newHelper, access: ROLE_DEFAULTS.helper }),
    );
  });

  it('changes directly on a profile nobody has claimed yet', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertSucceeds(
      updateDoc(doc(db, `${HOME}/members/m-unclaimed`), {
        role: 'carer',
        access: ROLE_DEFAULTS.carer,
      }),
    );
  });

  it('does not change directly on a claimed one — that is setMemberAccess', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertFails(
      updateDoc(doc(db, `${HOME}/members/${PEOPLE.cleaner.member}`), {
        access: ROLE_DEFAULTS.helper,
      }),
    );
  });

  it('accepts every role ADR-0003 names, and the old `member` an installed app still writes', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    for (const role of ['admin', 'parent', 'member', 'kid', 'helper', 'carer']) {
      await assertSucceeds(
        setDoc(doc(db, `${HOME}/members/m-${role}-new`), {
          ...newHelper,
          role,
          // A kid carries a parent's consent (accounts ADR-0005).
          ...(role === 'kid'
            ? {
                guardianConsent: {
                  byMemberId: PEOPLE.admin.member,
                  version: 1,
                  at: serverTimestamp(),
                },
              }
            : {}),
        }),
      );
    }
    await assertFails(setDoc(doc(db, `${HOME}/members/m-owner`), { ...newHelper, role: 'owner' }));
  });
});

describe('the invite step a new household opens', () => {
  beforeEach(async () => {
    await clearData();
    await givenAHouseholdOfEveryRole();
  });

  it('is closed by an admin, whether they finished it or skipped it', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertSucceeds(updateDoc(doc(db, HOME), { pendingSetupStep: null }));
  });

  it('is never reopened, nor set to anything else', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertFails(updateDoc(doc(db, HOME), { pendingSetupStep: 'somethingElse' }));
  });

  it('is not closed by anybody who is not an admin', async () => {
    for (const person of [PEOPLE.parent, PEOPLE.kid, PEOPLE.legacyHelper]) {
      await assertFails(updateDoc(doc(await asUser(person.uid), HOME), { pendingSetupStep: null }));
    }
  });

  it('cannot be used to smuggle another change past the settings rule', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertFails(
      updateDoc(doc(db, HOME), { pendingSetupStep: null, [`members.${PEOPLE.kid.uid}`]: 'admin' }),
    );
  });
});
