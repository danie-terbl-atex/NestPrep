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

/**
 * Calendar sync (calendar ADR-0003). Members read what the household may see
 * of its connected calendars; nobody but a Function writes any of it, and no
 * client reads a credential at all — not even the person who connected it.
 */
const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const HOME = `households/${HOUSEHOLD}`;
const CONNECTION = `${HOME}/calendarConnections/c1`;
const SYNCED = `${HOME}/syncedEvents/c1_abc`;
const FEED = `${HOME}/calendarFeed/current`;
const SECRET = 'calendarConnectionSecrets/c1';
const STATE = 'calendarOAuthStates/state-1';
const FEED_TOKEN = 'calendarFeeds/hash-1';

const connection = {
  provider: 'google',
  memberId: 'm-sam',
  ownerUid: SAM,
  accountLabel: 'sam@example.com',
  status: 'connected',
  eventCount: 1,
  lastSyncedAt: null,
  lastAttemptAt: null,
  createdAt: new Date(),
};

const syncedEvent = {
  connectionId: 'c1',
  provider: 'google',
  memberId: 'm-sam',
  title: 'Standup',
  date: '2026-10-01',
  endDate: '2026-10-01',
  startMinute: 540,
  endMinute: 555,
  fingerprint: 'f',
  syncedAt: new Date(),
};

async function givenAConnectedCalendar(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, HOME), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [THANDI]: 'helper' },
    });
    await setDoc(doc(db, CONNECTION), connection);
    await setDoc(doc(db, SYNCED), syncedEvent);
    await setDoc(doc(db, FEED), { url: 'https://feed.test/x', tokenHash: 'hash-1' });
    await setDoc(doc(db, SECRET), { householdId: HOUSEHOLD, credential: 'refresh-1' });
    await setDoc(doc(db, STATE), { uid: SAM, householdId: HOUSEHOLD });
    await setDoc(doc(db, FEED_TOKEN), { householdId: HOUSEHOLD });
  });
}

beforeEach(async () => {
  await clearData();
  await givenAConnectedCalendar();
});

describe('calendarConnections/{connectionId}', () => {
  it('every member reads the household’s connections, a stranger does not', async () => {
    await assertSucceeds(getDoc(doc(await asUser(THANDI), CONNECTION)));
    await assertSucceeds(getDocs(collection(await asUser(SAM), `${HOME}/calendarConnections`)));
    await assertFails(getDoc(doc(await asUser(STRANGER), CONNECTION)));
    await assertFails(getDoc(doc(await asSignedOut(), CONNECTION)));
  });

  it('nobody writes one, not even its owner or an admin', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, `${HOME}/calendarConnections/c2`), connection));
    await assertFails(updateDoc(doc(sam, CONNECTION), { status: 'revoked' }));
    await assertFails(updateDoc(doc(sam, CONNECTION), { ownerUid: THANDI }));
    await assertFails(deleteDoc(doc(sam, CONNECTION)));
  });
});

describe('syncedEvents/{syncedEventId}', () => {
  it('every member reads the week’s imported events, bounded by day', async () => {
    const thandi = await asUser(THANDI);
    await assertSucceeds(getDoc(doc(thandi, SYNCED)));
    await assertSucceeds(
      getDocs(
        query(
          collection(thandi, `${HOME}/syncedEvents`),
          where('date', '>=', '2026-09-28'),
          where('date', '<=', '2026-10-04'),
        ),
      ),
    );
    await assertFails(getDoc(doc(await asUser(STRANGER), SYNCED)));
  });

  it('an imported event cannot be written, edited or deleted from the app', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, `${HOME}/syncedEvents/forged`), syncedEvent));
    await assertFails(updateDoc(doc(sam, SYNCED), { title: 'Changed' }));
    await assertFails(deleteDoc(doc(sam, SYNCED)));
  });
});

describe('calendarFeed/{feedId}', () => {
  it('every member reads the feed link, a stranger does not', async () => {
    await assertSucceeds(getDoc(doc(await asUser(THANDI), FEED)));
    await assertFails(getDoc(doc(await asUser(STRANGER), FEED)));
  });

  it('nobody sets or resets it but the Function, which retires the old token with it', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, FEED), { url: 'https://evil.test', tokenHash: 'x' }));
    await assertFails(deleteDoc(doc(sam, FEED)));
  });
});

describe('the credentials', () => {
  for (const path of [SECRET, STATE, FEED_TOKEN]) {
    it(`${path.split('/')[0] ?? path} cannot be read by anybody, the owner and an admin included`, async () => {
      await assertFails(getDoc(doc(await asUser(SAM), path)));
      await assertFails(getDoc(doc(await asUser(THANDI), path)));
      await assertFails(getDoc(doc(await asSignedOut(), path)));
    });

    it(`${path.split('/')[0] ?? path} cannot be written by anybody`, async () => {
      const sam = await asUser(SAM);
      await assertFails(setDoc(doc(sam, path), { householdId: HOUSEHOLD }));
      await assertFails(deleteDoc(doc(sam, path)));
    });
  }

  it('the collection of secrets cannot even be listed', async () => {
    await assertFails(getDocs(collection(await asUser(SAM), 'calendarConnectionSecrets')));
  });

  it('while the Function’s own write, with the rules off, still lands', async () => {
    // The denials above are the rules, not an empty emulator: the documents are
    // there, and a rules-free context reads one back (lesson: a test that
    // asserts what already holds can never fail).
    await givenData(async (db: Firestore) => {
      await assertSucceeds(getDoc(doc(db, SECRET)));
    });
  });
});
