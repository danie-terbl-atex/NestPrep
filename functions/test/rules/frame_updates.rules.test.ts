import { collection, deleteDoc, doc, getDoc, getDocs, setDoc, updateDoc } from 'firebase/firestore';
import { getBytes, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import { HOME, HOUSEHOLD, PEOPLE, givenAHouseholdOfEveryRole } from './access_fixture';
import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  rulesEnvironment,
  storageAs,
  storageAsSignedOut,
  type FirebaseStorage,
  type Firestore,
} from './rules_harness';

const RELEASE = 'frameReleases/home-4';
const DEVICE = `frameDevices/${'a'.repeat(64)}`;
const APK = 'frameReleases/home/4.apk';
const FRAME = `${HOME}/frames/kitchen`;
const APK_BYTES = new Uint8Array([0x50, 0x4b, 0x03, 0x04]);

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await givenData(async (db) => {
    await setDoc(doc(db, FRAME), { name: 'Kitchen', lastSeenAt: null });
    await setDoc(doc(db, RELEASE), { app: 'home', versionCode: 4, stage: 'all', paused: false });
    await setDoc(doc(db, DEVICE), { ring: 'standard', installNowUntil: null });
  });
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), APK), APK_BYTES, {
      contentType: 'application/vnd.android.package-archive',
    });
  });
});

describe('frame releases and devices are closed to every client', () => {
  for (const [label, open] of [
    ['family', (): Promise<Firestore> => asUser(PEOPLE.admin.uid)],
    ['a helper', (): Promise<Firestore> => asUser(PEOPLE.cleaner.uid)],
    ['anybody signed out', asSignedOut],
  ] as const) {
    it(label, async () => {
      const db = await open();
      await assertFails(getDoc(doc(db, RELEASE)));
      await assertFails(getDocs(collection(db, 'frameReleases')));
      await assertFails(setDoc(doc(db, 'frameReleases/home-5'), { app: 'home', versionCode: 5 }));
      await assertFails(updateDoc(doc(db, RELEASE), { paused: true }));
      await assertFails(deleteDoc(doc(db, RELEASE)));
      await assertFails(getDoc(doc(db, DEVICE)));
      await assertFails(getDocs(collection(db, 'frameDevices')));
      await assertFails(setDoc(doc(db, `frameDevices/${'b'.repeat(64)}`), { ring: 'internal' }));
      await assertFails(updateDoc(doc(db, DEVICE), { ring: 'internal' }));
      await assertFails(deleteDoc(doc(db, DEVICE)));
    });
  }

  it('while family still reads its own frame', async () => {
    await assertSucceeds(getDoc(doc(await asUser(PEOPLE.admin.uid), FRAME)));
  });
});

describe('a release’s APK in Storage is closed to every client', () => {
  for (const [label, open] of [
    [
      'family',
      (): Promise<FirebaseStorage> => storageAs(PEOPLE.admin.uid, { [HOUSEHOLD]: 'admin' }, {}),
    ],
    ['anybody signed out', storageAsSignedOut],
  ] as const) {
    it(label, async () => {
      const storage = await open();
      await assertFails(getBytes(ref(storage, APK)));
      await assertFails(uploadBytes(ref(storage, 'frameReleases/home/5.apk'), APK_BYTES));
    });
  }

  it('while family still reads its own screensaver album', async () => {
    const path = `${HOME}/framePhotos/beach-0001`;
    await (
      await rulesEnvironment()
    ).withSecurityRulesDisabled(async (context) => {
      await uploadBytes(ref(context.storage(), path), new Uint8Array([0xff, 0xd8]), {
        contentType: 'image/jpeg',
        customMetadata: { uploadedByUid: PEOPLE.admin.uid },
      });
    });
    const storage = await storageAs(PEOPLE.admin.uid, { [HOUSEHOLD]: 'admin' }, {});
    await assertSucceeds(getBytes(ref(storage, path)));
  });
});
