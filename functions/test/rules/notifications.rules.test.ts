import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  type Firestore,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { HOME, HOUSEHOLD, KID_DEVICE, PEOPLE, givenAHouseholdOfEveryRole } from './access_fixture';
import {
  asKid,
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
} from './rules_harness';

/**
 * Notifications (notifications ADR-0001, ADR-0003): a person's own phones,
 * their own choices — which family may also make for a kid — and their own
 * inbox, which nobody else reads and only Functions write.
 */

const kidDevice = (): Promise<Firestore> =>
  asKid(KID_DEVICE, { householdId: HOUSEHOLD, memberId: PEOPLE.kid.member });

function settings(
  updatedBy: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    digest: { enabled: true, minute: 390 },
    digestSlot: 26,
    categories: { documents: true, handover: true, chores: false },
    quietHours: { enabled: true, startMinute: 1260, endMinute: 360 },
    updatedBy,
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

const settingsPath = (memberId: string): string => `${HOME}/notificationSettings/${memberId}`;
const inboxPath = (id: string): string => `${HOME}/notificationInbox/${id}`;

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await givenData(async (db) => {
    for (const [id, memberId] of [
      ['for-pat', PEOPLE.parent.member],
      ['for-kid', PEOPLE.kid.member],
      ['for-nomsa', PEOPLE.carer.member],
    ] as const) {
      await setDoc(doc(db, inboxPath(id)), {
        memberId,
        category: 'digest',
        title: 'Your Tuesday at a glance',
        body: '1 event',
        readAt: null,
        createdAt: new Date(),
      });
    }
    await setDoc(doc(db, `users/${PEOPLE.parent.uid}/pushTokens/token-pat`), {
      token: 'token-pat',
      platform: 'android',
      updatedAt: new Date(),
    });
  });
});

describe('a phone’s push token', () => {
  it('its own account registers, refreshes, reads and forgets it', async () => {
    const pat = await asUser(PEOPLE.parent.uid);
    const path = `users/${PEOPLE.parent.uid}/pushTokens/token-new`;
    await assertSucceeds(
      setDoc(doc(pat, path), { token: 'token-new', platform: 'ios', updatedAt: serverTimestamp() }),
    );
    await assertSucceeds(getDoc(doc(pat, path)));
    await assertSucceeds(deleteDoc(doc(pat, path)));
  });

  it('a kid tablet registers its own', async () => {
    const tablet = await kidDevice();
    await assertSucceeds(
      setDoc(doc(tablet, `users/${KID_DEVICE}/pushTokens/tablet-token`), {
        token: 'tablet-token',
        platform: 'android',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('nobody reads, writes or deletes another account’s', async () => {
    const sam = await asUser(PEOPLE.admin.uid);
    const path = `users/${PEOPLE.parent.uid}/pushTokens/token-pat`;
    await assertFails(getDoc(doc(sam, path)));
    await assertFails(deleteDoc(doc(sam, path)));
    await assertFails(
      setDoc(doc(sam, `users/${PEOPLE.parent.uid}/pushTokens/sams`), {
        token: 'sams',
        platform: 'android',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(getDoc(doc(await asSignedOut(), path)));
  });

  it('refuses a token filed under another id, an unknown platform, or a client’s clock', async () => {
    const pat = await asUser(PEOPLE.parent.uid);
    const path = `users/${PEOPLE.parent.uid}/pushTokens/token-x`;
    await assertFails(
      setDoc(doc(pat, path), {
        token: 'token-y',
        platform: 'android',
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      setDoc(doc(pat, path), { token: 'token-x', platform: 'web', updatedAt: serverTimestamp() }),
    );
    await assertFails(
      setDoc(doc(pat, path), { token: 'token-x', platform: 'android', updatedAt: new Date(0) }),
    );
    await assertFails(
      setDoc(doc(pat, path), {
        token: 'token-x',
        platform: 'android',
        updatedAt: serverTimestamp(),
        householdId: HOUSEHOLD,
      }),
    );
  });
});

describe('a person’s notification settings', () => {
  it('a person writes and reads their own', async () => {
    const pat = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(
      setDoc(doc(pat, settingsPath(PEOPLE.parent.member)), settings(PEOPLE.parent.member)),
    );
    await assertSucceeds(getDoc(doc(pat, settingsPath(PEOPLE.parent.member))));
  });

  it('a helper with no grant at all still manages their own', async () => {
    const thandi = await asUser(PEOPLE.cleaner.uid);
    await assertSucceeds(
      setDoc(doc(thandi, settingsPath(PEOPLE.cleaner.member)), settings(PEOPLE.cleaner.member)),
    );
  });

  it('family may turn a kid’s off; the kid’s tablet manages its own', async () => {
    const sam = await asUser(PEOPLE.admin.uid);
    await assertSucceeds(
      setDoc(
        doc(sam, settingsPath(PEOPLE.kid.member)),
        settings(PEOPLE.admin.member, {
          digest: { enabled: false, minute: 390 },
          digestSlot: null,
        }),
      ),
    );
    const tablet = await kidDevice();
    await assertSucceeds(getDoc(doc(tablet, settingsPath(PEOPLE.kid.member))));
    await assertSucceeds(
      setDoc(doc(tablet, settingsPath(PEOPLE.kid.member)), settings(PEOPLE.kid.member)),
    );
  });

  it('nobody writes or reads an adult’s but that adult — family included', async () => {
    const sam = await asUser(PEOPLE.admin.uid);
    await assertFails(
      setDoc(doc(sam, settingsPath(PEOPLE.carer.member)), settings(PEOPLE.admin.member)),
    );
    await assertFails(getDoc(doc(sam, settingsPath(PEOPLE.parent.member))));
    const nomsa = await asUser(PEOPLE.carer.uid);
    await assertFails(
      setDoc(doc(nomsa, settingsPath(PEOPLE.kid.member)), settings(PEOPLE.carer.member)),
    );
    await assertFails(
      setDoc(
        doc(await asUser('uid-stranger'), settingsPath(PEOPLE.parent.member)),
        settings('m-x'),
      ),
    );
  });

  it('refuses a digest slot that is not the chosen time, or a time off the quarter hour', async () => {
    const pat = await asUser(PEOPLE.parent.uid);
    const path = settingsPath(PEOPLE.parent.member);
    const me = PEOPLE.parent.member;
    for (const bad of [
      settings(me, { digestSlot: 3 }),
      settings(me, { digestSlot: null }),
      settings(me, { digest: { enabled: true, minute: 395 }, digestSlot: 26 }),
      settings(me, { digest: { enabled: false, minute: 390 }, digestSlot: 26 }),
      settings(me, { digest: { enabled: true, minute: 1440 }, digestSlot: 96 }),
    ]) {
      await assertFails(setDoc(doc(pat, path), bad));
    }
  });

  it('refuses an unknown category, a bad quiet window, somebody else’s name, or a client clock', async () => {
    const pat = await asUser(PEOPLE.parent.uid);
    const path = settingsPath(PEOPLE.parent.member);
    const me = PEOPLE.parent.member;
    for (const bad of [
      settings(me, { categories: { medication: true } }),
      settings(me, { categories: { documents: 'yes' } }),
      settings(me, { quietHours: { enabled: true, startMinute: -1, endMinute: 360 } }),
      settings(me, { quietHours: { enabled: true } }),
      settings(PEOPLE.admin.member),
      settings(me, { updatedAt: new Date(0) }),
      settings(me, { extra: true }),
    ]) {
      await assertFails(setDoc(doc(pat, path), bad));
    }
  });

  it('nobody deletes them', async () => {
    const pat = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(
      setDoc(doc(pat, settingsPath(PEOPLE.parent.member)), settings(PEOPLE.parent.member)),
    );
    await assertFails(deleteDoc(doc(pat, settingsPath(PEOPLE.parent.member))));
  });
});

describe('a person’s inbox', () => {
  it('its person lists it, marks one read and clears one', async () => {
    const pat = await asUser(PEOPLE.parent.uid);
    await assertSucceeds(
      getDocs(
        query(
          collection(pat, `${HOME}/notificationInbox`),
          where('memberId', '==', PEOPLE.parent.member),
        ),
      ),
    );
    await assertSucceeds(updateDoc(doc(pat, inboxPath('for-pat')), { readAt: serverTimestamp() }));
    await assertSucceeds(deleteDoc(doc(pat, inboxPath('for-pat'))));
  });

  it('a kid tablet reads its kid’s', async () => {
    await assertSucceeds(getDoc(doc(await kidDevice(), inboxPath('for-kid'))));
  });

  it('nobody reads another person’s — not family, not by listing everything', async () => {
    const sam = await asUser(PEOPLE.admin.uid);
    await assertFails(getDoc(doc(sam, inboxPath('for-pat'))));
    await assertFails(getDoc(doc(sam, inboxPath('for-kid'))));
    await assertFails(getDocs(collection(sam, `${HOME}/notificationInbox`)));
    await assertFails(getDoc(doc(await kidDevice(), inboxPath('for-pat'))));
    await assertFails(getDoc(doc(await asUser('uid-stranger'), inboxPath('for-pat'))));
  });

  it('marking read changes only that, on the server’s clock; nobody writes a notification', async () => {
    const pat = await asUser(PEOPLE.parent.uid);
    await assertFails(updateDoc(doc(pat, inboxPath('for-pat')), { readAt: new Date(0) }));
    await assertFails(
      updateDoc(doc(pat, inboxPath('for-pat')), { readAt: serverTimestamp(), title: 'Hacked' }),
    );
    await assertFails(
      setDoc(doc(pat, inboxPath('made-up')), { memberId: PEOPLE.parent.member, title: 'Hi' }),
    );
    const sam = await asUser(PEOPLE.admin.uid);
    await assertFails(updateDoc(doc(sam, inboxPath('for-pat')), { readAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(sam, inboxPath('for-pat'))));
  });
});
