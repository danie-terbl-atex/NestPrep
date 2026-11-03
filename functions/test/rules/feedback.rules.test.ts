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
import { afterAll, beforeEach, describe, it } from 'vitest';

import {
  asKid,
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  closeRulesEnvironment,
  givenData,
} from './rules_harness';

/**
 * Feedback (feedback ADR-0001): an account creates it, in one shape, and no
 * client reads, changes or deletes it — not even the account that sent it.
 */

const SAM = 'uid-sam';
const ALEX = 'uid-alex';
const KID_TABLET = 'uid-kid-tablet';
const HOME = 'h1';
const OTHER_HOME = 'h2';

function feedback(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    uid: SAM,
    kind: 'problem',
    message: 'The grocery list forgets what I ticked.',
    area: 'groceries',
    screen: '/household/:householdId/lists',
    householdId: HOME,
    mayContact: true,
    appVersion: '0.9.0',
    appBuild: 8,
    platform: 'android',
    createdAt: serverTimestamp(),
    ...overrides,
  };
}

beforeEach(async () => {
  await clearData();
  await givenData(async (db) => {
    await setDoc(doc(db, `households/${HOME}`), { name: 'Home', members: { [SAM]: 'admin' } });
    await setDoc(doc(db, `households/${OTHER_HOME}`), {
      name: 'Elsewhere',
      members: { [ALEX]: 'admin' },
    });
    await setDoc(doc(db, 'feedback/sent'), feedback({ createdAt: new Date() }));
  });
});

afterAll(closeRulesEnvironment);

describe('sending feedback', () => {
  it('an account sends it in its own name, from its household', async () => {
    await assertSucceeds(setDoc(doc(await asUser(SAM), 'feedback/f1'), feedback()));
  });

  it('with no household, no area and no screen', async () => {
    await assertSucceeds(
      setDoc(
        doc(await asUser(SAM), 'feedback/f1'),
        feedback({ householdId: null, area: null, screen: null, kind: 'idea' }),
      ),
    );
  });

  it('never in somebody else’s name', async () => {
    await assertFails(setDoc(doc(await asUser(ALEX), 'feedback/f1'), feedback()));
  });

  it('never naming a household the sender is not in', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), 'feedback/f1'), feedback({ householdId: OTHER_HOME })),
    );
  });

  it('never signed out', async () => {
    await assertFails(setDoc(doc(await asSignedOut(), 'feedback/f1'), feedback()));
  });

  it('never from a kid device', async () => {
    const tablet = await asKid(KID_TABLET, { householdId: HOME, memberId: 'mia' });
    await assertFails(
      setDoc(doc(tablet, 'feedback/f1'), feedback({ uid: KID_TABLET, householdId: null })),
    );
  });

  it('only in a kind the rules know', async () => {
    await assertFails(setDoc(doc(await asUser(SAM), 'feedback/f1'), feedback({ kind: 'rant' })));
  });

  it('only in an area the rules know', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), 'feedback/f1'), feedback({ area: 'settings' })),
    );
  });

  it('never empty, untrimmed or longer than 2000 characters', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, 'feedback/f1'), feedback({ message: '' })));
    await assertFails(setDoc(doc(sam, 'feedback/f1'), feedback({ message: ' padded ' })));
    await assertFails(setDoc(doc(sam, 'feedback/f1'), feedback({ message: 'a'.repeat(2001) })));
    await assertSucceeds(setDoc(doc(sam, 'feedback/f1'), feedback({ message: 'a'.repeat(2000) })));
  });

  it('stamped with the server’s time, not one the phone chose', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), 'feedback/f1'), feedback({ createdAt: new Date() })),
    );
  });

  it('with no field the rules do not list, and none missing', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, 'feedback/f1'), feedback({ status: 'resolved' })));
    const withoutConsent = feedback();
    delete withoutConsent['mayContact'];
    await assertFails(setDoc(doc(sam, 'feedback/f1'), withoutConsent));
  });

  it('only from a platform the rules know, with a whole build number', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, 'feedback/f1'), feedback({ platform: 'windows' })));
    await assertFails(setDoc(doc(sam, 'feedback/f1'), feedback({ appBuild: '8' })));
  });
});

describe('what was sent', () => {
  it('cannot be read, listed, changed or deleted by the account that sent it', async () => {
    const sam = await asUser(SAM);
    await assertFails(getDoc(doc(sam, 'feedback/sent')));
    await assertFails(getDocs(collection(sam, 'feedback')));
    await assertFails(updateDoc(doc(sam, 'feedback/sent'), { message: 'Never mind.' }));
    await assertFails(deleteDoc(doc(sam, 'feedback/sent')));
  });

  it('cannot be read by anybody else either', async () => {
    await assertFails(getDoc(doc(await asUser(ALEX), 'feedback/sent')));
    await assertFails(getDocs(collection(await asSignedOut(), 'feedback')));
  });
});
