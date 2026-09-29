import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import { ROLE_DEFAULTS, storageGrant } from '../../src/household/access';
import { LOOK_ONLY, CLEANING_ONLY } from './access_fixture';
import {
  assertFails,
  assertSucceeds,
  clearData,
  rulesEnvironment,
  storageAs,
  storageAsSignedOut,
  type FirebaseStorage,
} from './rules_harness';

/**
 * The nanny hub's photos — house-guide spots, child cards and handover
 * entries (nanny-hub ADR-0003). Storage rules cannot read Firestore, so the
 * grant arrives on the token as the `access` claim, built here with the same
 * `storageGrant` the Functions write it with.
 */
const HOUSEHOLD = 'h1';
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
const PNG = new Uint8Array([0x89, 0x50, 0x4e, 0x47]);

function pathTo(photoId: string): string {
  return `households/${HOUSEHOLD}/nannyHub/${photoId}`;
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

async function givenANappyShelfPhoto(uploadedByUid: string): Promise<void> {
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), pathTo('nappy-shelf')), JPEG, {
      contentType: 'image/jpeg',
      customMetadata: { uploadedByUid },
    });
  });
}

const carer = (): Promise<FirebaseStorage> =>
  storageAs(
    'uid-nomsa',
    { [HOUSEHOLD]: 'carer' },
    { [HOUSEHOLD]: storageGrant(ROLE_DEFAULTS.carer) },
  );

describe('nanny hub photos in Storage, by grant', () => {
  beforeEach(async () => {
    await clearData();
    await givenANappyShelfPhoto('uid-sam');
  });

  it('lets a carer on the carer defaults see them and add one', async () => {
    const storage = await carer();
    await assertSucceeds(getBytes(ref(storage, pathTo('nappy-shelf'))));
    await assertSucceeds(upload(storage, 'handover-0001', 'uid-nomsa'));
  });

  it('lets a helper at view see them and add nothing', async () => {
    const storage = await storageAs(
      'uid-vera',
      { [HOUSEHOLD]: 'helper' },
      { [HOUSEHOLD]: storageGrant(LOOK_ONLY) },
    );
    await assertSucceeds(getBytes(ref(storage, pathTo('nappy-shelf'))));
    await assertFails(upload(storage, 'handover-0002', 'uid-vera'));
  });

  it('shows the cleaner and a kid nothing, whose grants hold no hub', async () => {
    for (const [uid, role, grant] of [
      ['uid-thandi', 'helper', CLEANING_ONLY],
      ['uid-kid', 'kid', ROLE_DEFAULTS.kid],
    ] as const) {
      const storage = await storageAs(
        uid,
        { [HOUSEHOLD]: role },
        { [HOUSEHOLD]: storageGrant(grant) },
      );
      await assertFails(getBytes(ref(storage, pathTo('nappy-shelf'))));
      await assertFails(upload(storage, 'handover-0003', uid));
    }
  });

  it('shows a carer on a token from before household ADR-0003 nothing', async () => {
    const storage = await storageAs('uid-new', { [HOUSEHOLD]: 'carer' });
    await assertFails(getBytes(ref(storage, pathTo('nappy-shelf'))));
  });

  it('refuses anybody signed out', async () => {
    await assertFails(getBytes(ref(await storageAsSignedOut(), pathTo('nappy-shelf'))));
  });

  it('refuses anything the app would not have made: not a JPEG, too big, a bad name', async () => {
    const storage = await carer();
    await assertFails(upload(storage, 'handover-0004', 'uid-nomsa', PNG, 'image/png'));
    const tooBig = new Uint8Array(2 * 1024 * 1024 + 1);
    await assertFails(upload(storage, 'handover-0005', 'uid-nomsa', tooBig));
    await assertFails(upload(storage, 'short', 'uid-nomsa'));
  });

  it('refuses a photo stamped with somebody else’s uid, and any overwrite', async () => {
    const storage = await carer();
    await assertFails(upload(storage, 'handover-0006', 'uid-sam'));
    await assertFails(upload(storage, 'nappy-shelf', 'uid-nomsa'));
  });

  it('lets a carer remove their own photo and not a parent’s; family removes any', async () => {
    const storage = await carer();
    await assertFails(deleteObject(ref(storage, pathTo('nappy-shelf'))));
    await assertSucceeds(upload(storage, 'handover-0007', 'uid-nomsa'));
    await assertSucceeds(deleteObject(ref(storage, pathTo('handover-0007'))));

    const parent = await storageAs('uid-pat', { [HOUSEHOLD]: 'parent' }, {});
    await assertSucceeds(deleteObject(ref(parent, pathTo('nappy-shelf'))));
  });
});
