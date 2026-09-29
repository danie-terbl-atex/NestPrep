import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';
import { ROLE_DEFAULTS } from '../../src/household/access';

/**
 * Shared links (documents ADR-0006) and the V2 switches (foundation
 * ADR-0014).
 *
 * The family reads every link of the household; anybody else only a link
 * they made, while they are still in it. Nobody writes a link from the app —
 * not its count, not its status, not even to stop it (that is a callable), so
 * an open cannot be hidden and a locked link cannot be unlocked. A link's
 * secrets are closed to every client. The switches are readable by anybody
 * and writable by nobody.
 */
const SAM = 'uid-sam';
const ALEX = 'uid-alex';
const THANDI = 'uid-thandi';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const HOME = `households/${HOUSEHOLD}`;
const BY_SAM = `${HOME}/documentShares/s-sam`;
const BY_THANDI = `${HOME}/documentShares/s-thandi`;
const TOKEN = 'documentShareTokens/hash-1';
const FLAGS = 'appConfig/flags';

function aShare(createdByUid: string, createdBy: string): Record<string, unknown> {
  return {
    scope: 'vault',
    ownerMemberId: createdBy,
    documentId: 'card',
    documentName: 'Medical aid card',
    contentType: 'application/pdf',
    createdBy,
    createdByUid,
    createdAt: new Date(),
    expiresAt: new Date(Date.now() + 3_600_000),
    shiftId: null,
    hasPin: true,
    status: 'active',
    openCount: 0,
    lastOpenedAt: null,
    purgeAt: new Date(Date.now() + 40 * 86_400_000),
  };
}

beforeEach(async () => {
  await clearData();
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, HOME), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [ALEX]: 'parent', [THANDI]: 'helper' },
      access: { [THANDI]: { ...ROLE_DEFAULTS.helper, documents: 'edit' } },
    });
    await setDoc(doc(db, BY_SAM), aShare(SAM, 'm-sam'));
    await setDoc(doc(db, BY_THANDI), aShare(THANDI, 'm-thandi'));
    await setDoc(doc(db, TOKEN), {
      householdId: HOUSEHOLD,
      shareId: 's-sam',
      pinHash: 'aa',
      pinSalt: 'bb',
      failedPinAttempts: 0,
    });
    await setDoc(doc(db, FLAGS), { documentShareLinks: true });
  });
});

describe('documentShares/{shareId} — reading', () => {
  it('the family reads every link, and lists the live ones', async () => {
    for (const uid of [SAM, ALEX]) {
      const family = await asUser(uid);
      await assertSucceeds(getDoc(doc(family, BY_SAM)));
      await assertSucceeds(getDoc(doc(family, BY_THANDI)));
      await assertSucceeds(
        getDocs(
          query(
            collection(family, `${HOME}/documentShares`),
            where('status', '==', 'active'),
            where('expiresAt', '>', new Date()),
          ),
        ),
      );
    }
  });

  it('a helper reads the link she made, and lists only her own', async () => {
    const thandi = await asUser(THANDI);
    await assertSucceeds(getDoc(doc(thandi, BY_THANDI)));
    await assertSucceeds(
      getDocs(
        query(
          collection(thandi, `${HOME}/documentShares`),
          where('createdByUid', '==', THANDI),
          where('status', '==', 'active'),
        ),
      ),
    );
  });

  it("a helper does not read a parent's link, or list the household's", async () => {
    const thandi = await asUser(THANDI);
    await assertFails(getDoc(doc(thandi, BY_SAM)));
    await assertFails(getDocs(collection(thandi, `${HOME}/documentShares`)));
  });

  it('a stranger and a signed-out caller read nothing', async () => {
    await assertFails(getDoc(doc(await asUser(STRANGER), BY_SAM)));
    await assertFails(getDoc(doc(await asSignedOut(), BY_SAM)));
  });

  it('a helper who left the household no longer reads the link she made', async () => {
    await givenData(async (db: Firestore) => {
      await updateDoc(doc(db, HOME), { members: { [SAM]: 'admin', [ALEX]: 'parent' } });
    });
    await assertFails(getDoc(doc(await asUser(THANDI), BY_THANDI)));
  });
});

describe('documentShares/{shareId} — writing', () => {
  it('nobody makes a link from the app, not even an admin', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, `${HOME}/documentShares/forged`), aShare(SAM, 'm-sam')));
  });

  it('nobody hides an open, unlocks a link or stops one by writing it', async () => {
    const sam = await asUser(SAM);
    await assertFails(updateDoc(doc(sam, BY_SAM), { openCount: 0 }));
    await assertFails(updateDoc(doc(sam, BY_SAM), { status: 'revoked' }));
    await assertFails(updateDoc(doc(sam, BY_SAM), { expiresAt: new Date(Date.now() + 1e10) }));
    const thandi = await asUser(THANDI);
    await assertFails(updateDoc(doc(thandi, BY_THANDI), { status: 'active' }));
  });

  it('nobody deletes a link from the app', async () => {
    await assertFails(deleteDoc(doc(await asUser(SAM), BY_SAM)));
    await assertFails(deleteDoc(doc(await asUser(THANDI), BY_THANDI)));
  });
});

describe('documentShareTokens/{tokenHash}', () => {
  it('no client reads or writes a link’s secrets, not even the family', async () => {
    const sam = await asUser(SAM);
    await assertFails(getDoc(doc(sam, TOKEN)));
    await assertFails(getDocs(collection(sam, 'documentShareTokens')));
    await assertFails(updateDoc(doc(sam, TOKEN), { failedPinAttempts: 0 }));
    await assertFails(setDoc(doc(sam, 'documentShareTokens/hash-2'), { shareId: 's-sam' }));
    await assertFails(deleteDoc(doc(sam, TOKEN)));
  });
});

describe('appConfig/{configId}', () => {
  it('anybody reads the switches, signed in or not', async () => {
    await assertSucceeds(getDoc(doc(await asUser(STRANGER), FLAGS)));
    await assertSucceeds(getDoc(doc(await asSignedOut(), FLAGS)));
  });

  it('nobody lists the collection or reads another config document', async () => {
    const sam = await asUser(SAM);
    await assertFails(getDocs(collection(sam, 'appConfig')));
    await assertFails(getDoc(doc(sam, 'appConfig/secrets')));
  });

  it('nobody writes a switch from the app, not even an admin', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, FLAGS), { documentShareLinks: false }));
    await assertFails(updateDoc(doc(sam, FLAGS), { documentOfflineCopies: true }));
    await assertFails(deleteDoc(doc(sam, FLAGS)));
  });
});
