import { deleteObject, getBytes, listAll, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import { ROLE_DEFAULTS, storageGrant } from '../../src/household/access';
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
 * A household's screensaver album (photo-frames ADR-0006): family fills it,
 * sees it and empties it; nobody else touches it, and a frame reads it only
 * through the Functions.
 */
const HOUSEHOLD = 'h1';
const ALBUM = `households/${HOUSEHOLD}/framePhotos`;
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
const PNG = new Uint8Array([0x89, 0x50, 0x4e, 0x47]);

function pathTo(photoId: string): string {
  return `${ALBUM}/${photoId}`;
}

function upload(
  storage: FirebaseStorage,
  photoId: string,
  uid: string,
  bytes: Uint8Array = JPEG,
  contentType = 'image/jpeg',
): Promise<unknown> {
  return uploadBytes(ref(storage, pathTo(photoId)), bytes, {
    contentType,
    customMetadata: { uploadedByUid: uid },
  });
}

async function givenABeachPhoto(): Promise<void> {
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), pathTo('beach-0001')), JPEG, {
      contentType: 'image/jpeg',
      customMetadata: { uploadedByUid: 'uid-sam' },
    });
  });
}

const parent = (): Promise<FirebaseStorage> => storageAs('uid-pat', { [HOUSEHOLD]: 'parent' }, {});

describe('a household’s screensaver album in Storage', () => {
  beforeEach(async () => {
    await clearData();
    await givenABeachPhoto();
  });

  for (const role of ['admin', 'parent', 'member']) {
    it(`lets ${role} add, see, list and remove photos`, async () => {
      const storage = await storageAs(`uid-${role}`, { [HOUSEHOLD]: role }, {});
      await assertSucceeds(upload(storage, 'party-0002', `uid-${role}`));
      await assertSucceeds(getBytes(ref(storage, pathTo('beach-0001'))));
      await assertSucceeds(listAll(ref(storage, ALBUM)));
      await assertSucceeds(deleteObject(ref(storage, pathTo('beach-0001'))));
      await assertSucceeds(deleteObject(ref(storage, pathTo('party-0002'))));
    });
  }

  it('shows a helper, a carer and a kid nothing, whatever their grant', async () => {
    for (const [uid, role, grant] of [
      ['uid-thandi', 'helper', ROLE_DEFAULTS.helper],
      ['uid-nomsa', 'carer', ROLE_DEFAULTS.carer],
      ['uid-kid', 'kid', ROLE_DEFAULTS.kid],
    ] as const) {
      const storage = await storageAs(
        uid,
        { [HOUSEHOLD]: role },
        { [HOUSEHOLD]: storageGrant(grant) },
      );
      await assertFails(getBytes(ref(storage, pathTo('beach-0001'))));
      await assertFails(listAll(ref(storage, ALBUM)));
      await assertFails(upload(storage, 'helper-0003', uid));
      await assertFails(deleteObject(ref(storage, pathTo('beach-0001'))));
    }
  });

  it('shows another household’s family, a stranger and anybody signed out nothing', async () => {
    for (const storage of [
      await storageAs('uid-other', { h2: 'admin' }, {}),
      await storageAsStranger('uid-stranger'),
      await storageAsSignedOut(),
    ]) {
      await assertFails(getBytes(ref(storage, pathTo('beach-0001'))));
      await assertFails(listAll(ref(storage, ALBUM)));
      await assertFails(upload(storage, 'other-0004', 'uid-other'));
      await assertFails(deleteObject(ref(storage, pathTo('beach-0001'))));
    }
  });

  it('refuses anything the app would not have made: not a JPEG, past 1 MiB, a bad name', async () => {
    const storage = await parent();
    await assertFails(upload(storage, 'a-png-0005', 'uid-pat', PNG, 'image/png'));
    await assertFails(upload(storage, 'too-big-06', 'uid-pat', new Uint8Array(1024 * 1024 + 1)));
    await assertSucceeds(upload(storage, 'just-fits-7', 'uid-pat', new Uint8Array(1024 * 1024)));
    await assertFails(upload(storage, 'short', 'uid-pat'));
    await assertFails(upload(storage, 'x'.repeat(65), 'uid-pat'));
    await assertFails(upload(storage, 'has.dot.0008', 'uid-pat'));
  });

  it('refuses a photo stamped with somebody else’s uid, or with nobody’s, and any overwrite', async () => {
    const storage = await parent();
    await assertFails(upload(storage, 'stamped-009', 'uid-sam'));
    await assertFails(
      uploadBytes(ref(storage, pathTo('unstamped-1')), JPEG, { contentType: 'image/jpeg' }),
    );
    await assertFails(upload(storage, 'beach-0001', 'uid-pat'));
  });
});
