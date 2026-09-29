import { collection, deleteDoc, doc, getDoc, getDocs, setDoc, updateDoc } from 'firebase/firestore';
import { beforeAll, describe, it } from 'vitest';

import { HOME, KID_DEVICE, PEOPLE, RECORDS, type Person } from './access_fixture';
import {
  A_MIRROR,
  DADS,
  DADS_OWN_RECORDS,
  HANDOVER,
  LINK,
  REQUEST,
  givenTwoLinkedHomes,
  mirrorPaths,
} from './coparent_fixture';
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
 * The boundary between two homes (household ADR-0004).
 *
 * Each household reads its own copy of the link under its own grants, and
 * nothing else: not the other home's copy, not the authority that names both
 * households, not a code, and not one record of the other household's own.
 * No client writes any of it — only the co-parenting Functions do, to both
 * copies at once.
 *
 * Mum's home is the access fixture's household with every role, so every
 * grant is asked every question; Dad's home is a second household whose admin
 * and parent are asked every question about Mum's.
 */

const MUM = mirrorPaths(HOME);
const DAD = mirrorPaths(DADS.home);

/** Who in Mum's home may read what, from household ADR-0004's table. */
const READS: Record<Person, { link: boolean; handover: boolean; request: boolean }> = {
  admin: { link: true, handover: true, request: true },
  parent: { link: true, handover: true, request: true },
  legacyMember: { link: true, handover: true, request: true },
  // calendar view, medical none
  kid: { link: true, handover: false, request: false },
  // calendar view, medical view
  carer: { link: true, handover: true, request: false },
  // nothing but cleaning jobs
  cleaner: { link: false, handover: false, request: false },
  // view everywhere: reads, but may not see the adults' negotiation
  viewer: { link: true, handover: true, request: false },
  // a helper from before ADR-0003 keeps edit everywhere
  legacyHelper: { link: true, handover: true, request: true },
};

const everyone = Object.keys(PEOPLE) as Person[];

async function readAs(db: Firestore, path: string, allowed: boolean): Promise<void> {
  const read = getDoc(doc(db, path));
  await (allowed ? assertSucceeds(read) : assertFails(read));
}

beforeAll(async () => {
  await clearData();
  await givenTwoLinkedHomes();
});

describe('reading your own home’s copy, by role', () => {
  for (const person of everyone) {
    const expected = READS[person];
    for (const kind of ['link', 'handover', 'request'] as const) {
      it(`${expected[kind] ? 'lets' : 'denies'} ${person} read the ${kind}`, async () => {
        await readAs(await asUser(PEOPLE[person].uid), MUM[kind], expected[kind]);
      });
    }
  }

  it('lets a kid device read the link, as its kid profile would, and nothing more', async () => {
    const db = await asKid(KID_DEVICE, { householdId: 'h-access', memberId: PEOPLE.kid.member });
    await readAs(db, MUM.link, true);
    await readAs(db, MUM.handover, false);
    await readAs(db, MUM.request, false);
  });

  it('lets family list the links, handovers and requests', async () => {
    const db = await asUser(PEOPLE.admin.uid);
    await assertSucceeds(getDocs(collection(db, `${HOME}/coParentLinks`)));
    await assertSucceeds(getDocs(collection(db, `${MUM.link}/handovers`)));
    await assertSucceeds(getDocs(collection(db, `${MUM.link}/requests`)));
  });

  it('refuses the lists to whoever the grant keeps out', async () => {
    await assertFails(
      getDocs(collection(await asUser(PEOPLE.cleaner.uid), `${HOME}/coParentLinks`)),
    );
    await assertFails(getDocs(collection(await asUser(PEOPLE.kid.uid), `${MUM.link}/handovers`)));
    await assertFails(getDocs(collection(await asUser(PEOPLE.carer.uid), `${MUM.link}/requests`)));
  });

  it('refuses everything to somebody signed out', async () => {
    const db = await asSignedOut();
    for (const path of Object.values(MUM)) await readAs(db, path, false);
  });
});

describe('the other home reads nothing of yours', () => {
  const dadsAdults = [DADS.admin.uid, DADS.parent.uid];

  it('not your copy of the link, its handovers or its requests', async () => {
    for (const uid of dadsAdults) {
      const db = await asUser(uid);
      for (const path of Object.values(MUM)) await readAs(db, path, false);
    }
  });

  it('not by listing them either', async () => {
    const db = await asUser(DADS.admin.uid);
    await assertFails(getDocs(collection(db, `${HOME}/coParentLinks`)));
    await assertFails(getDocs(collection(db, `${MUM.link}/handovers`)));
    await assertFails(getDocs(collection(db, `${MUM.link}/requests`)));
  });

  it('not your household, your people, or any record your home keeps', async () => {
    const paths = [
      HOME,
      `${HOME}/members/${PEOPLE.admin.member}`,
      ...Object.values(RECORDS).flat(),
    ];
    for (const uid of dadsAdults) {
      const db = await asUser(uid);
      for (const path of paths) await readAs(db, path, false);
    }
  });

  it('not by listing your people, your week or your documents', async () => {
    const db = await asUser(DADS.admin.uid);
    for (const name of ['members', 'events', 'tasks', 'groceryItems', 'documents']) {
      await assertFails(getDocs(collection(db, `${HOME}/${name}`)));
    }
  });

  it('and it reads its own copy of the link, which is the whole of what is shared', async () => {
    const db = await asUser(DADS.admin.uid);
    for (const path of Object.values(DAD)) await readAs(db, path, true);
  });

  it('while nobody in your home reads the other home’s copy or its records', async () => {
    for (const person of everyone) {
      const db = await asUser(PEOPLE[person].uid);
      for (const path of [...Object.values(DAD), DADS.home, ...DADS_OWN_RECORDS]) {
        await readAs(db, path, false);
      }
    }
  });
});

describe('the authority and the codes are closed to every client', () => {
  const closed = [`coParentLinks/${LINK}`, 'coParentInvites/ABCD2345'];

  it('refuses a read by either home’s admin, or anybody signed out', async () => {
    for (const db of [
      await asUser(PEOPLE.admin.uid),
      await asUser(DADS.admin.uid),
      await asSignedOut(),
    ]) {
      for (const path of closed) await readAs(db, path, false);
      await assertFails(getDocs(collection(db, 'coParentLinks')));
      await assertFails(getDocs(collection(db, 'coParentInvites')));
    }
  });

  it('refuses a write by either home’s admin', async () => {
    for (const uid of [PEOPLE.admin.uid, DADS.admin.uid]) {
      const db = await asUser(uid);
      await assertFails(setDoc(doc(db, 'coParentInvites/ZZZZ2345'), { householdId: 'h-access' }));
      await assertFails(setDoc(doc(db, 'coParentLinks/new'), { status: 'active' }));
      await assertFails(updateDoc(doc(db, `coParentLinks/${LINK}`), { status: 'ended' }));
      await assertFails(deleteDoc(doc(db, `coParentLinks/${LINK}`)));
    }
  });
});

describe('no client writes a copy — only the Functions, to both at once', () => {
  it('refuses family creating, changing or deleting the link', async () => {
    for (const uid of [PEOPLE.admin.uid, PEOPLE.parent.uid]) {
      const db = await asUser(uid);
      await assertFails(setDoc(doc(db, `${HOME}/coParentLinks/new`), A_MIRROR));
      await assertFails(updateDoc(doc(db, MUM.link), { status: 'ended' }));
      await assertFails(updateDoc(doc(db, MUM.link), { overrides: { '2026-10-02': 'a' } }));
      await assertFails(deleteDoc(doc(db, MUM.link)));
    }
  });

  it('refuses family writing a handover or a request directly', async () => {
    for (const uid of [PEOPLE.admin.uid, PEOPLE.parent.uid]) {
      const db = await asUser(uid);
      await assertFails(setDoc(doc(db, `${MUM.link}/handovers/2026-10-05`), HANDOVER));
      await assertFails(updateDoc(doc(db, MUM.handover), { note: 'changed' }));
      await assertFails(deleteDoc(doc(db, MUM.handover)));
      await assertFails(setDoc(doc(db, `${MUM.link}/requests/new`), REQUEST));
      await assertFails(updateDoc(doc(db, MUM.request), { status: 'accepted' }));
      await assertFails(deleteDoc(doc(db, MUM.request)));
    }
  });

  it('refuses a legacy helper with edit everywhere, and a kid device', async () => {
    const helper = await asUser(PEOPLE.legacyHelper.uid);
    await assertFails(updateDoc(doc(helper, MUM.link), { status: 'ended' }));
    await assertFails(setDoc(doc(helper, `${MUM.link}/handovers/2026-10-05`), HANDOVER));
    const kid = await asKid(KID_DEVICE, { householdId: 'h-access', memberId: PEOPLE.kid.member });
    await assertFails(updateDoc(doc(kid, MUM.link), { status: 'ended' }));
  });

  it('refuses the other home’s admin writing into your copy', async () => {
    const db = await asUser(DADS.admin.uid);
    await assertFails(updateDoc(doc(db, MUM.link), { status: 'ended' }));
    await assertFails(setDoc(doc(db, `${MUM.link}/handovers/2026-10-05`), HANDOVER));
    await assertFails(setDoc(doc(db, `${MUM.link}/requests/new`), REQUEST));
    await assertFails(setDoc(doc(db, `${HOME}/events/from-dad`), { title: 'Mine now' }));
  });

  it('refuses a home writing its own copy too — even Dad’s admin in Dad’s home', async () => {
    const db = await asUser(DADS.admin.uid);
    await assertFails(updateDoc(doc(db, DAD.link), { status: 'ended' }));
    await assertFails(setDoc(doc(db, `${DAD.link}/handovers/2026-10-05`), HANDOVER));
    await assertFails(updateDoc(doc(db, DAD.request), { status: 'accepted' }));
  });
});

describe('the feature flags', () => {
  it('are read by anybody signed in, including a kid device', async () => {
    await readAs(await asUser(PEOPLE.cleaner.uid), 'appConfig/flags', true);
    await readAs(await asUser(DADS.admin.uid), 'appConfig/flags', true);
    const kid = await asKid(KID_DEVICE, { householdId: 'h-access', memberId: PEOPLE.kid.member });
    await readAs(kid, 'appConfig/flags', true);
  });

  it('are refused to somebody signed out, and written by no client', async () => {
    await readAs(await asSignedOut(), 'appConfig/flags', false);
    const db = await asUser(PEOPLE.admin.uid);
    await assertFails(setDoc(doc(db, 'appConfig/flags'), { coParenting: false }));
    await assertFails(updateDoc(doc(db, 'appConfig/flags'), { coParenting: false }));
  });
});
