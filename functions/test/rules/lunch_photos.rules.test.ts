import { deleteDoc, doc, getDoc, setDoc } from 'firebase/firestore';
import { deleteObject, getBytes, listAll, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import { ROLE_DEFAULTS, storageGrant, uniformGrant } from '../../src/household/access';
import { SAM, givenAHouseholdOfTwo } from './household_fixture';
import {
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  rulesEnvironment,
  storageAs,
  storageAsSignedOut,
  storageAsStranger,
  type FirebaseStorage,
  type Firestore,
} from './rules_harness';

/**
 * A lunch box's picture (lunch-box ADR-0015). Only the `lunchPhoto` Function
 * writes the picture or its document. A catalogue-only box's picture is
 * shared, and anybody signed in may load it; a household's own is for
 * whoever may see that household's lunches. Storage rules cannot read
 * Firestore, so the grant arrives on the token, built with the same
 * `storageGrant` the Functions write it with.
 */

const HOUSEHOLD = 'h1';
const KEY = '0123456789abcdef0123456789abcdef01234567';
const SHARED = `lunchPhotos/${KEY}.jpg`;
const OWN = `households/${HOUSEHOLD}/lunchPhotos/${KEY}.jpg`;
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);

async function givenThePictures(): Promise<void> {
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    for (const path of [SHARED, OWN]) {
      await uploadBytes(ref(context.storage(), path), JPEG, { contentType: 'image/jpeg' });
    }
  });
}

const parent = (): Promise<FirebaseStorage> => storageAs(SAM, { [HOUSEHOLD]: 'parent' }, {});

const carer = (): Promise<FirebaseStorage> =>
  storageAs(
    'uid-nomsa',
    { [HOUSEHOLD]: 'carer' },
    { [HOUSEHOLD]: storageGrant(ROLE_DEFAULTS.carer) },
  );

const helperWithoutLunch = (): Promise<FirebaseStorage> =>
  storageAs(
    'uid-thandi',
    { [HOUSEHOLD]: 'helper' },
    { [HOUSEHOLD]: storageGrant(ROLE_DEFAULTS.helper) },
  );

const memberElsewhere = (): Promise<FirebaseStorage> => storageAs('uid-other', { h2: 'admin' }, {});

describe('a shared lunch box picture in Storage', () => {
  beforeEach(async () => {
    await clearData();
    await givenThePictures();
  });

  it('is loaded by anybody signed in, in any household or none', async () => {
    for (const storage of [await parent(), await memberElsewhere(), await storageAsStranger('u')]) {
      await assertSucceeds(getBytes(ref(storage, SHARED)));
    }
  });

  it('is refused to anybody signed out', async () => {
    await assertFails(getBytes(ref(await storageAsSignedOut(), SHARED)));
  });

  it('is never listed, written, replaced or removed by a client', async () => {
    const storage = await parent();
    await assertFails(listAll(ref(storage, 'lunchPhotos')));
    await assertFails(uploadBytes(ref(storage, `lunchPhotos/${KEY}x.jpg`), JPEG));
    await assertFails(uploadBytes(ref(storage, SHARED), JPEG));
    await assertFails(deleteObject(ref(storage, SHARED)));
  });
});

describe('a household’s own lunch box picture in Storage', () => {
  beforeEach(async () => {
    await clearData();
    await givenThePictures();
  });

  it('is loaded by family, and by a carer whose grant shows lunches', async () => {
    await assertSucceeds(getBytes(ref(await parent(), OWN)));
    await assertSucceeds(getBytes(ref(await carer(), OWN)));
  });

  it('is loaded by a helper given lunch at view', async () => {
    const storage = await storageAs(
      'uid-vera',
      { [HOUSEHOLD]: 'helper' },
      { [HOUSEHOLD]: storageGrant({ ...uniformGrant('none'), lunch: 'view' }) },
    );
    await assertSucceeds(getBytes(ref(storage, OWN)));
  });

  it('is refused to a member whose grant holds no lunches', async () => {
    await assertFails(getBytes(ref(await helperWithoutLunch(), OWN)));
  });

  it('is refused to anybody not in the household, and to anybody signed out', async () => {
    await assertFails(getBytes(ref(await memberElsewhere(), OWN)));
    await assertFails(getBytes(ref(await storageAsStranger('u'), OWN)));
    await assertFails(getBytes(ref(await storageAsSignedOut(), OWN)));
  });

  it('is never listed, written, replaced or removed by a client, family included', async () => {
    const storage = await parent();
    await assertFails(listAll(ref(storage, `households/${HOUSEHOLD}/lunchPhotos`)));
    await assertFails(
      uploadBytes(ref(storage, `households/${HOUSEHOLD}/lunchPhotos/new.jpg`), JPEG),
    );
    await assertFails(uploadBytes(ref(storage, OWN), JPEG));
    await assertFails(deleteObject(ref(storage, OWN)));
  });
});

describe('the pictures’ documents in Firestore', () => {
  let home = '';

  beforeEach(async () => {
    await clearData();
    home = await givenAHouseholdOfTwo();
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, `lunchPhotos/${KEY}`), { status: 'ready', path: SHARED });
      await setDoc(doc(db, `${home}/lunchPhotos/${KEY}`), { status: 'ready', path: OWN });
    });
  });

  it('are read by the Function alone — not even the household’s admin', async () => {
    const sam = await asUser(SAM);
    await assertFails(getDoc(doc(sam, `lunchPhotos/${KEY}`)));
    await assertFails(getDoc(doc(sam, `${home}/lunchPhotos/${KEY}`)));
  });

  it('cannot be written, marked ready or removed by anybody', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, `lunchPhotos/${KEY}`), { status: 'pending' }));
    await assertFails(setDoc(doc(sam, `${home}/lunchPhotos/other`), { status: 'ready' }));
    await assertFails(deleteDoc(doc(sam, `lunchPhotos/${KEY}`)));
    await assertFails(deleteDoc(doc(sam, `${home}/lunchPhotos/${KEY}`)));
  });
});
