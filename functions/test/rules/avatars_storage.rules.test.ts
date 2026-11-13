import { deleteObject, getBytes, listAll, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import { HOME, HOUSEHOLD, KID_DEVICE, PEOPLE, givenAHouseholdOfEveryRole } from './access_fixture';
import type { Person } from './access_fixture';
import {
  assertFails,
  assertSucceeds,
  clearData,
  rulesEnvironment,
  storageAs,
  storageAsSignedOut,
  storageAsStranger,
  type FirebaseStorage,
} from './rules_harness';

/**
 * A member's pictures (avatars ADR-0001). These rules read Firestore live, so
 * every member here carries a *forged admin claim*, and a kid device none at
 * all: what lets anybody in is the household document, never the token.
 */

const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
const FORGED = { [HOUSEHOLD]: 'admin' };
const KID = PEOPLE.kid.member;
const CLEANER = PEOPLE.cleaner.member;
const HASH = '0123456789abcdef0123456789abcdef';
const OTHER_HASH = 'fedcba9876543210fedcba9876543210';
const folder = (memberId: string): string => `${HOME}/avatars/${memberId}`;
const STORED = `${folder(KID)}/${HASH}.jpg`;
const KEPT = `${folder(KID)}/keepsakes/kept-0001.jpg`;
const INBOXED = `${folder(KID)}/inbox/drawing-0001.jpg`;

const storageOf = (person: Person): Promise<FirebaseStorage> =>
  storageAs(PEOPLE[person].uid, FORGED);

async function kidDevice(): Promise<FirebaseStorage> {
  const context = (await rulesEnvironment()).authenticatedContext(KID_DEVICE, {
    kidProfile: { householdId: HOUSEHOLD, memberId: KID },
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

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    for (const path of [STORED, KEPT, INBOXED]) {
      await uploadBytes(ref(context.storage(), path), JPEG, {
        contentType: 'image/jpeg',
        customMetadata: { uploadedByUid: PEOPLE.admin.uid },
      });
    }
  });
});

describe('seeing a member’s pictures', () => {
  it('lets everyone in the household see them, whatever their grant', async () => {
    for (const person of Object.keys(PEOPLE) as Person[]) {
      for (const path of [STORED, KEPT, INBOXED]) {
        await assertSucceeds(getBytes(ref(await storageOf(person), path)));
      }
    }
  });

  it('lets a kid device see them on no household claim at all', async () => {
    await assertSucceeds(getBytes(ref(await kidDevice(), STORED)));
    await assertSucceeds(getBytes(ref(await kidDevice(), KEPT)));
  });

  it('denies another household, a stranger with a forged claim and nobody at all', async () => {
    await assertFails(getBytes(ref(await storageAs('uid-olivia', { 'h-other': 'admin' }), STORED)));
    await assertFails(getBytes(ref(await storageAs('uid-olivia', FORGED), STORED)));
    await assertFails(getBytes(ref(await storageAsStranger('uid-stranger'), STORED)));
    await assertFails(getBytes(ref(await storageAsSignedOut(), STORED)));
  });

  it('is never listed', async () => {
    await assertFails(listAll(ref(await storageOf('admin'), folder(KID))));
    await assertFails(listAll(ref(await kidDevice(), `${folder(KID)}/keepsakes`)));
  });
});

describe('putting a picture up', () => {
  const NEW = `${folder(KID)}/${OTHER_HASH}.jpg`;

  it('lets family put one up for anyone, and a member for themselves', async () => {
    await assertSucceeds(upload(await storageOf('parent'), NEW, PEOPLE.parent.uid));
    await assertSucceeds(
      upload(
        await storageOf('cleaner'),
        `${folder(CLEANER)}/${OTHER_HASH}.jpg`,
        PEOPLE.cleaner.uid,
      ),
    );
    await assertSucceeds(
      upload(await storageOf('kid'), `${folder(KID)}/${'a'.repeat(32)}.jpg`, PEOPLE.kid.uid),
    );
  });

  it('lets a kid device put one up for its own child only', async () => {
    await assertSucceeds(upload(await kidDevice(), NEW, KID_DEVICE));
    await assertFails(
      upload(await kidDevice(), `${folder(CLEANER)}/${OTHER_HASH}.jpg`, KID_DEVICE),
    );
  });

  it('denies a helper or a kid putting one up for somebody else, and a stranger', async () => {
    await assertFails(upload(await storageOf('cleaner'), NEW, PEOPLE.cleaner.uid));
    await assertFails(
      upload(await storageOf('kid'), `${folder(CLEANER)}/${OTHER_HASH}.jpg`, PEOPLE.kid.uid),
    );
    await assertFails(upload(await storageAs('uid-olivia', FORGED), NEW, 'uid-olivia'));
    await assertFails(upload(await storageAsSignedOut(), NEW, 'nobody'));
  });

  it('takes only a JPEG named by its hash, at most 512 KB, stamped with who sent it', async () => {
    const parent = await storageOf('parent');
    const uid = PEOPLE.parent.uid;
    await assertFails(upload(parent, NEW, uid, { contentType: 'image/png' }));
    await assertFails(upload(parent, NEW, uid, { bytes: new Uint8Array(512 * 1024 + 1) }));
    await assertSucceeds(upload(parent, NEW, uid, { bytes: new Uint8Array(512 * 1024) }));
    await assertFails(upload(parent, `${folder(KID)}/${'b'.repeat(32)}.jpg`, PEOPLE.admin.uid));
    for (const name of ['short.jpg', `${HASH.toUpperCase()}.jpg`, `${HASH}.png`, HASH]) {
      await assertFails(upload(parent, `${folder(KID)}/${name}`, uid));
    }
  });

  it('never replaces a picture, and leaves every delete to the Functions', async () => {
    await assertFails(upload(await storageOf('admin'), STORED, PEOPLE.admin.uid));
    await assertFails(deleteObject(ref(await storageOf('admin'), STORED)));
    await assertFails(deleteObject(ref(await kidDevice(), STORED)));
  });
});

describe('the inbox a picture is made from', () => {
  const NEW = `${folder(KID)}/inbox/drawing-0002.jpg`;

  it('takes a JPEG of at most 2 MB from family or the member', async () => {
    await assertSucceeds(
      upload(await storageOf('admin'), NEW, PEOPLE.admin.uid, {
        bytes: new Uint8Array(2 * 1024 * 1024),
      }),
    );
    await assertSucceeds(
      upload(await kidDevice(), `${folder(KID)}/inbox/drawing-0003.jpg`, KID_DEVICE),
    );
  });

  it('denies anything bigger, of another kind, badly named, or for somebody else', async () => {
    const admin = await storageOf('admin');
    const uid = PEOPLE.admin.uid;
    await assertFails(upload(admin, NEW, uid, { bytes: new Uint8Array(2 * 1024 * 1024 + 1) }));
    await assertFails(upload(admin, NEW, uid, { contentType: 'image/heic' }));
    await assertFails(upload(admin, `${folder(KID)}/inbox/short.jpg`, uid));
    await assertFails(upload(await storageOf('cleaner'), NEW, PEOPLE.cleaner.uid));
    await assertFails(upload(await storageOf('admin'), INBOXED, uid));
    await assertFails(deleteObject(ref(admin, INBOXED)));
  });
});

describe('keepsakes', () => {
  it('are written and removed by Functions alone', async () => {
    await assertFails(
      upload(await storageOf('admin'), `${folder(KID)}/keepsakes/kept-0002.jpg`, PEOPLE.admin.uid),
    );
    await assertFails(
      upload(await kidDevice(), `${folder(KID)}/keepsakes/kept-0003.jpg`, KID_DEVICE),
    );
    await assertFails(deleteObject(ref(await storageOf('admin'), KEPT)));
  });
});
