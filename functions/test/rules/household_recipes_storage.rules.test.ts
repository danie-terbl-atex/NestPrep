import { doc, setDoc, updateDoc } from 'firebase/firestore';
import { deleteObject, getBytes, listAll, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import { HOME, HOUSEHOLD, KID_DEVICE, PEOPLE, givenAHouseholdOfEveryRole } from './access_fixture';
import type { Person } from './access_fixture';
import {
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  rulesEnvironment,
  storageAs,
  storageAsSignedOut,
  storageAsStranger,
  type FirebaseStorage,
} from './rules_harness';

/**
 * A household's own recipe photos (recipes ADR-0007). These rules read
 * Firestore live, never the token's claims, so every member here carries a
 * *forged admin claim*: a test that passes with it proves the claim isn't what
 * lets anybody in.
 */

const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
const FORGED = { [HOUSEHOLD]: 'admin' };
const FOLDER = `${HOME}/recipePhotos/own-0123456789abcdef0123`;
const STORED = `${FOLDER}/AbCd1234-hero.jpg`;
const NEW = `${FOLDER}/WxYz5678-card.jpg`;

const storageOf = (person: Person): Promise<FirebaseStorage> =>
  storageAs(PEOPLE[person].uid, FORGED);

async function kidDevice(): Promise<FirebaseStorage> {
  const context = (await rulesEnvironment()).authenticatedContext(KID_DEVICE, {
    kidProfile: { householdId: HOUSEHOLD, memberId: PEOPLE.kid.member },
  });
  return context.storage();
}

function upload(
  storage: FirebaseStorage,
  path: string,
  uid: string,
  options: { contentType?: string; bytes?: Uint8Array } = {},
): Promise<unknown> {
  return uploadBytes(ref(storage, path), options.bytes ?? JPEG, {
    contentType: options.contentType ?? 'image/jpeg',
    customMetadata: { uploadedByUid: uid },
  });
}

async function givenCarerHoldsMeals(level: string): Promise<void> {
  await givenData(async (db) => {
    await setDoc(
      doc(db, HOME),
      { access: { [PEOPLE.carer.uid]: { meals: level } } },
      { merge: true },
    );
  });
}

const givenCarerIsShiftOnly = (): Promise<void> =>
  givenData(async (db) => {
    await updateDoc(doc(db, HOME), { [`shiftOnly.${PEOPLE.carer.member}`]: true });
  });

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), STORED), JPEG, {
      contentType: 'image/jpeg',
      customMetadata: { uploadedByUid: PEOPLE.admin.uid },
    });
  });
});

describe('seeing a recipe’s photo', () => {
  it('lets family, a helper with meals at view and a kid with meals at view see it', async () => {
    for (const person of ['admin', 'parent', 'legacyMember', 'legacyHelper', 'viewer', 'kid']) {
      await assertSucceeds(getBytes(ref(await storageOf(person as Person), STORED)));
    }
  });

  it('lets a kid device see it through its profile’s grant, on no household claim', async () => {
    await assertSucceeds(getBytes(ref(await kidDevice(), STORED)));
  });

  it('denies a kid device whose profile holds no meals, or is no longer a kid', async () => {
    await givenData(async (db) => {
      await updateDoc(doc(db, `${HOME}/members/${PEOPLE.kid.member}`), { 'access.meals': 'none' });
    });
    await assertFails(getBytes(ref(await kidDevice(), STORED)));
    await givenData(async (db) => {
      await updateDoc(doc(db, `${HOME}/members/${PEOPLE.kid.member}`), {
        'access.meals': 'view',
        role: 'helper',
      });
    });
    await assertFails(getBytes(ref(await kidDevice(), STORED)));
  });

  it('denies a cleaner, whatever their token claims', async () => {
    await assertFails(getBytes(ref(await storageOf('cleaner'), STORED)));
  });

  it('denies another household, a stranger and nobody at all', async () => {
    await assertFails(getBytes(ref(await storageAs('uid-olivia', { 'h-other': 'admin' }), STORED)));
    await assertFails(getBytes(ref(await storageAs('uid-olivia', FORGED), STORED)));
    await assertFails(getBytes(ref(await storageAsStranger('uid-stranger'), STORED)));
    await assertFails(getBytes(ref(await storageAsSignedOut(), STORED)));
  });

  it('is never listed', async () => {
    await assertFails(listAll(ref(await storageOf('admin'), FOLDER)));
  });
});

describe('a shift-only carer', () => {
  const carer = (): Promise<FirebaseStorage> =>
    storageAs(PEOPLE.carer.uid, { [HOUSEHOLD]: 'carer' });

  it('sees and uploads on shift, and neither off it', async () => {
    await givenCarerHoldsMeals('edit');
    await assertSucceeds(getBytes(ref(await carer(), STORED)));
    await givenCarerIsShiftOnly();
    await assertFails(getBytes(ref(await carer(), STORED)));
    await assertFails(upload(await carer(), NEW, PEOPLE.carer.uid));
    await givenData(async (db) => {
      await setDoc(doc(db, `${HOME}/nannyShiftPasses/${PEOPLE.carer.member}`), {
        startsAt: new Date(Date.now() - 60_000),
        endsAt: new Date(Date.now() + 60_000),
      });
    });
    await assertSucceeds(getBytes(ref(await carer(), STORED)));
    await assertSucceeds(upload(await carer(), NEW, PEOPLE.carer.uid));
  });
});

describe('uploading a recipe’s photo', () => {
  it('lets anybody with meals at edit put one up, before the recipe exists', async () => {
    await assertSucceeds(upload(await storageOf('parent'), NEW, PEOPLE.parent.uid));
    await givenCarerHoldsMeals('edit');
    await assertSucceeds(
      upload(
        await storageAs(PEOPLE.carer.uid, { [HOUSEHOLD]: 'carer' }),
        `${FOLDER}/Carer1234-hero.jpg`,
        PEOPLE.carer.uid,
      ),
    );
  });

  it('denies meals at view, a kid, a kid device and a stranger', async () => {
    await assertFails(upload(await storageOf('viewer'), NEW, PEOPLE.viewer.uid));
    await assertFails(upload(await storageOf('kid'), NEW, PEOPLE.kid.uid));
    await assertFails(upload(await kidDevice(), NEW, KID_DEVICE));
    await assertFails(upload(await storageAsStranger('uid-stranger'), NEW, 'uid-stranger'));
  });

  it('refuses anything but a JPEG, anything over 2 MB, and an unstamped one', async () => {
    const storage = await storageOf('admin');
    const uid = PEOPLE.admin.uid;
    await assertFails(upload(storage, NEW, uid, { contentType: 'image/png' }));
    await assertFails(upload(storage, NEW, uid, { bytes: new Uint8Array(2 * 1024 * 1024 + 1) }));
    await assertFails(upload(storage, NEW, PEOPLE.parent.uid));
  });

  it('refuses a path that is not an own recipe’s card or hero', async () => {
    const storage = await storageOf('admin');
    const uid = PEOPLE.admin.uid;
    await assertFails(upload(storage, `${FOLDER}/WxYz5678.jpg`, uid));
    await assertFails(upload(storage, `${FOLDER}/WxYz5678-thumb.jpg`, uid));
    await assertFails(upload(storage, `${FOLDER}/short-card.jpg`, uid));
    await assertFails(
      upload(storage, `${HOME}/recipePhotos/ai-0123456789abcdef0123/WxYz5678-card.jpg`, uid),
    );
  });

  it('never replaces one', async () => {
    await assertFails(upload(await storageOf('admin'), STORED, PEOPLE.admin.uid));
  });
});

describe('deleting a recipe’s photo', () => {
  it('lets anybody with meals at edit remove one', async () => {
    await assertSucceeds(deleteObject(ref(await storageOf('parent'), STORED)));
  });

  it('denies meals at view, a kid device, a stranger and nobody at all', async () => {
    await assertFails(deleteObject(ref(await storageOf('viewer'), STORED)));
    await assertFails(deleteObject(ref(await kidDevice(), STORED)));
    await assertFails(deleteObject(ref(await storageAsStranger('uid-stranger'), STORED)));
    await assertFails(deleteObject(ref(await storageAsSignedOut(), STORED)));
  });
});
