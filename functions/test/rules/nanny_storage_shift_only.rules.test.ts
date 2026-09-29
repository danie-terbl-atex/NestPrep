import { getBytes, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import { ROLE_DEFAULTS, storageGrant } from '../../src/household/access';
import { HOUSEHOLD, PEOPLE } from './access_fixture';
import { CARER } from './nanny_fixture';
import { givenABookingAndPass, givenAHubWithTwoCarers, givenShiftOnly } from './nanny_v2_fixture';
import {
  assertFails,
  assertSucceeds,
  clearData,
  rulesEnvironment,
  storageAs,
  type FirebaseStorage,
} from './rules_harness';

/**
 * A shift-only carer and the hub's photos (nanny-hub ADR-0006). The token's
 * grant cannot know the time, so Storage reads Firestore live: the household
 * says who is shift-only, their pass says when their booked shift is — and
 * outside it (15 minutes either side) the photos are refused.
 */
const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
const pathTo = (photoId: string): string => `households/${HOUSEHOLD}/nannyHub/${photoId}`;

const carer = (): Promise<FirebaseStorage> =>
  storageAs(
    CARER.uid,
    { [HOUSEHOLD]: 'carer' },
    { [HOUSEHOLD]: storageGrant(ROLE_DEFAULTS.carer) },
  );

function upload(storage: FirebaseStorage, photoId: string, uid: string): Promise<unknown> {
  return uploadBytes(ref(storage, pathTo(photoId)), JPEG, {
    contentType: 'image/jpeg',
    customMetadata: { uploadedByUid: uid },
  });
}

const booked = (startsInMinutes: number, endsInMinutes: number): Promise<void> =>
  givenABookingAndPass({
    bookingId: 'nomsa-shift',
    carerMemberId: CARER.member,
    startsInMinutes,
    endsInMinutes,
  });

beforeEach(async () => {
  await clearData();
  await givenAHubWithTwoCarers();
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), pathTo('nappy-shelf')), JPEG, {
      contentType: 'image/jpeg',
      customMetadata: { uploadedByUid: PEOPLE.admin.uid },
    });
  });
});

describe('a shift-only carer and the hub’s photos', () => {
  it('sees and adds them during the booked shift', async () => {
    await givenShiftOnly(CARER.member);
    await booked(-60, 60);
    const storage = await carer();
    await assertSucceeds(getBytes(ref(storage, pathTo('nappy-shelf'))));
    await assertSucceeds(upload(storage, 'handover-0101', CARER.uid));
  });

  it('is refused before the shift, outside the grace', async () => {
    await givenShiftOnly(CARER.member);
    await booked(120, 300);
    const storage = await carer();
    await assertFails(getBytes(ref(storage, pathTo('nappy-shelf'))));
    await assertFails(upload(storage, 'handover-0102', CARER.uid));
  });

  it('is refused after the shift, and with no pass at all', async () => {
    await givenShiftOnly(CARER.member);
    const storage = await carer();
    await assertFails(getBytes(ref(storage, pathTo('nappy-shelf'))));
    await booked(-300, -120);
    await assertFails(getBytes(ref(storage, pathTo('nappy-shelf'))));
  });

  it('leaves a carer who is not shift-only reading at any time', async () => {
    const storage = await carer();
    await assertSucceeds(getBytes(ref(storage, pathTo('nappy-shelf'))));
  });

  it('never narrows family, even marked', async () => {
    await givenShiftOnly(PEOPLE.admin.member);
    const storage = await storageAs(PEOPLE.admin.uid, { [HOUSEHOLD]: 'admin' });
    await assertSucceeds(getBytes(ref(storage, pathTo('nappy-shelf'))));
  });
});
