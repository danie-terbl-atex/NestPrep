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

/** Sam admin and claimed, Thandi helper and claimed, Kid a member nobody claimed. */
async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `households/${HOUSEHOLD}`), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
      createdBy: SAM,
      createdAt: new Date(),
    });
    await setDoc(doc(db, `households/${HOUSEHOLD}/members/${SAM_MEMBER}`), {
      displayName: 'Sam Parent',
      color: 'violet',
      role: 'admin',
      claimedBy: SAM,
      createdAt: new Date(),
    });
    await setDoc(doc(db, `households/${HOUSEHOLD}/members/${THANDI_MEMBER}`), {
      displayName: 'Thandi',
      color: 'mint',
      role: 'helper',
      claimedBy: THANDI,
      createdAt: new Date(),
    });
    await setDoc(doc(db, `households/${HOUSEHOLD}/members/${KID_MEMBER}`), {
      displayName: 'Kid',
      color: 'sky',
      role: 'member',
      birthday: '2017-09-18',
      claimedBy: null,
      createdAt: new Date(),
    });
  });
}

const newMember = {
  displayName: 'Gran',
  color: 'amber',
  role: 'member',
  claimedBy: null,
  createdAt: serverTimestamp(),
};

describe('households/{id}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets any member read the household', async () => {
    await assertSucceeds(getDoc(doc(await asUser(SAM), `households/${HOUSEHOLD}`)));
    await assertSucceeds(getDoc(doc(await asUser(THANDI), `households/${HOUSEHOLD}`)));
  });

  it('denies a stranger reading it', async () => {
    await assertFails(getDoc(doc(await asUser(STRANGER), `households/${HOUSEHOLD}`)));
  });

  it('lets an admin rename it and change its timezone', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      updateDoc(doc(db, `households/${HOUSEHOLD}`), {
        name: 'The Parker Family',
        timeZone: 'Europe/London',
      }),
    );
  });

  it('denies a non-admin member renaming it', async () => {
    const db = await asUser(THANDI);
    await assertFails(updateDoc(doc(db, `households/${HOUSEHOLD}`), { name: 'Mine now' }));
  });

  it('denies anybody writing the membership map — only Functions do', async () => {
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(doc(db, `households/${HOUSEHOLD}`), {
        members: { [SAM]: 'admin', [STRANGER]: 'admin' },
      }),
    );
  });

  it('denies creating or deleting a household from a client', async () => {
    const db = await asUser(SAM);
    await assertFails(
      setDoc(doc(db, 'households/h2'), {
        name: 'Mine',
        timeZone: 'UTC',
        members: { [SAM]: 'admin' },
      }),
    );
    await assertFails(deleteDoc(doc(db, `households/${HOUSEHOLD}`)));
  });

  it('denies an empty name', async () => {
    const db = await asUser(SAM);
    await assertFails(updateDoc(doc(db, `households/${HOUSEHOLD}`), { name: '' }));
  });
});

describe('households/{id}/members/{memberId}', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets every member read every profile', async () => {
    const db = await asUser(THANDI);
    await assertSucceeds(getDoc(doc(db, `households/${HOUSEHOLD}/members/${KID_MEMBER}`)));
  });

  it('denies a stranger reading a profile', async () => {
    const db = await asUser(STRANGER);
    await assertFails(getDoc(doc(db, `households/${HOUSEHOLD}/members/${SAM_MEMBER}`)));
  });

  it('lets an admin add an unclaimed profile', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gran`), newMember));
  });

  it('denies a non-admin adding a profile', async () => {
    const db = await asUser(THANDI);
    await assertFails(setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gran`), newMember));
  });

  it('denies adding a profile already claimed by somebody', async () => {
    const db = await asUser(SAM);
    await assertFails(
      setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gran`), {
        ...newMember,
        claimedBy: STRANGER,
      }),
    );
  });

  it('denies a role that is not one of the three', async () => {
    const db = await asUser(SAM);
    await assertFails(
      setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gran`), {
        ...newMember,
        role: 'owner',
      }),
    );
  });

  it('denies a profile that dates its own creation', async () => {
    const db = await asUser(SAM);
    await assertFails(
      setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gran`), {
        ...newMember,
        createdAt: new Date('2000-01-01'),
      }),
    );
  });

  it('lets an admin rename and recolour anybody', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      updateDoc(doc(db, `households/${HOUSEHOLD}/members/${THANDI_MEMBER}`), {
        displayName: 'Thandi M',
        color: 'teal',
      }),
    );
  });

  it('lets an admin change the role of a profile nobody has claimed', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      updateDoc(doc(db, `households/${HOUSEHOLD}/members/${KID_MEMBER}`), { role: 'helper' }),
    );
  });

  it('denies changing the role of a claimed profile — that would leave the map behind', async () => {
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(doc(db, `households/${HOUSEHOLD}/members/${THANDI_MEMBER}`), { role: 'admin' }),
    );
  });

  it('denies claiming a profile from a client', async () => {
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(doc(db, `households/${HOUSEHOLD}/members/${KID_MEMBER}`), { claimedBy: SAM }),
    );
  });

  it('denies a member editing their own profile when they are not an admin', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      updateDoc(doc(db, `households/${HOUSEHOLD}/members/${THANDI_MEMBER}`), {
        displayName: 'Boss',
      }),
    );
  });

  it('denies deleting a profile from a client — removeMember does that', async () => {
    const db = await asUser(SAM);
    await assertFails(deleteDoc(doc(db, `households/${HOUSEHOLD}/members/${KID_MEMBER}`)));
  });
});

describe('households/{id}/members/{memberId} — the birthday (birthdays ADR-0001)', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
  });

  it('lets an admin add a profile with a birthday', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gran`), {
        ...newMember,
        birthday: '1952-04-30',
      }),
    );
  });

  it('lets one be added with no year, which some households do not know', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gran`), {
        ...newMember,
        birthday: '--04-30',
      }),
    );
  });

  it('lets one be added with none at all, as a null and as an absent field', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gran`), {
        ...newMember,
        birthday: null,
      }),
    );
    // `newMember` has no birthday key. Every profile written before the field
    // existed looks exactly like this, and must still be writable (BE-10).
    await assertSucceeds(setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gogo`), newMember));
  });

  it('denies a birthday that is not one', async () => {
    const db = await asUser(SAM);
    for (const wrong of ['', 'yesterday', '30-04-1952', '1952-13-30', '1952-04-32', '--00-30']) {
      await assertFails(
        setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gran`), {
          ...newMember,
          birthday: wrong,
        }),
      );
    }
  });

  it('denies a birthday that is not a string at all', async () => {
    const db = await asUser(SAM);
    await assertFails(
      setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gran`), {
        ...newMember,
        birthday: 19520430,
      }),
    );
  });

  it('lets an admin set, change and clear one on an existing profile', async () => {
    const db = await asUser(SAM);
    const kid = doc(db, `households/${HOUSEHOLD}/members/${KID_MEMBER}`);
    await assertSucceeds(updateDoc(kid, { birthday: '2017-09-19' }));
    await assertSucceeds(updateDoc(kid, { birthday: '--09-19' }));
    await assertSucceeds(updateDoc(kid, { birthday: null }));
  });

  it('lets an admin set one on a claimed profile without touching the role', async () => {
    const db = await asUser(SAM);
    await assertSucceeds(
      updateDoc(doc(db, `households/${HOUSEHOLD}/members/${THANDI_MEMBER}`), {
        birthday: '1988-02-29',
      }),
    );
  });

  it('denies updating a profile to a malformed birthday', async () => {
    const db = await asUser(SAM);
    await assertFails(
      updateDoc(doc(db, `households/${HOUSEHOLD}/members/${KID_MEMBER}`), {
        birthday: 'sometime in September',
      }),
    );
  });

  it('denies a non-admin setting anybody"s birthday, including their own', async () => {
    const db = await asUser(THANDI);
    await assertFails(
      updateDoc(doc(db, `households/${HOUSEHOLD}/members/${THANDI_MEMBER}`), {
        birthday: '1988-02-29',
      }),
    );
    await assertFails(
      updateDoc(doc(db, `households/${HOUSEHOLD}/members/${KID_MEMBER}`), {
        birthday: '2017-01-01',
      }),
    );
  });

  it('denies a stranger setting one', async () => {
    const db = await asUser(STRANGER);
    await assertFails(
      updateDoc(doc(db, `households/${HOUSEHOLD}/members/${KID_MEMBER}`), {
        birthday: '2017-01-01',
      }),
    );
  });

  it('still denies a field nobody named, now that the list has grown', async () => {
    // The birthday was added to `hasOnly`; deny-by-default has to survive it.
    const db = await asUser(SAM);
    await assertFails(
      setDoc(doc(db, `households/${HOUSEHOLD}/members/m-gran`), {
        ...newMember,
        birthday: '1952-04-30',
        nickname: 'Gran',
      }),
    );
    await assertFails(
      updateDoc(doc(db, `households/${HOUSEHOLD}/members/${KID_MEMBER}`), {
        nickname: 'Kiddo',
      }),
    );
  });
});
