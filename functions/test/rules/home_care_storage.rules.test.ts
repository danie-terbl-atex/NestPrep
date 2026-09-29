import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import {
  HOME,
  KID_DEVICE,
  PEOPLE,
  givenAHouseholdOfEveryRole,
  type Person,
} from './access_fixture';
import { JOBS, givenHomeCareRecords } from './home_care_fixture';
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
 * Before and after photos of cleaning jobs (home-care ADR-0003). These rules
 * read Firestore live — the household's grant and the job's helper — and never
 * the token's claims, so every caller here is handed a *forged admin claim*:
 * a test that passes with it proves the claim is not what lets anybody in.
 */

const JPEG = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
const FORGED = { 'h-access': 'admin' };

const photo = (job: string, name: string): string => `${job}/${name}`;
const storageOf = (person: Person): Promise<FirebaseStorage> =>
  storageAs(PEOPLE[person].uid, FORGED);

async function givenAPhoto(path: string): Promise<void> {
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), path), JPEG, {
      contentType: 'image/jpeg',
      customMetadata: { uploadedByUid: PEOPLE.admin.uid },
    });
  });
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
  await givenHomeCareRecords({ viewers: { status: 'inProgress', revision: 1 } });
  for (const job of Object.values(JOBS)) await givenAPhoto(photo(job, 'before'));
});

describe('seeing a job’s photos', () => {
  it('lets family, the legacy helper and the look-only helper see any job’s photo', async () => {
    for (const person of [
      'admin',
      'parent',
      'legacyMember',
      'legacyHelper',
      'viewer',
    ] as Person[]) {
      await assertSucceeds(getBytes(ref(await storageOf(person), photo(JOBS.nobodys, 'before'))));
    }
  });

  it('lets the cleaner see her own job’s photo', async () => {
    await assertSucceeds(getBytes(ref(await storageOf('cleaner'), photo(JOBS.cleaners, 'before'))));
  });

  it('denies the cleaner anybody else’s job’s photo', async () => {
    await assertFails(getBytes(ref(await storageOf('cleaner'), photo(JOBS.nobodys, 'before'))));
  });

  it('denies the carer and the kid, whatever their token claims', async () => {
    await assertFails(getBytes(ref(await storageOf('carer'), photo(JOBS.cleaners, 'before'))));
    await assertFails(getBytes(ref(await storageOf('kid'), photo(JOBS.cleaners, 'before'))));
  });

  it('denies a kid device, a stranger and nobody at all', async () => {
    const path = photo(JOBS.cleaners, 'before');
    await assertFails(getBytes(ref(await storageAs(KID_DEVICE, FORGED), path)));
    await assertFails(getBytes(ref(await storageAsStranger('uid-stranger'), path)));
    await assertFails(getBytes(ref(await storageAsSignedOut(), path)));
  });
});

describe('the before photo', () => {
  const NEW = `${HOME}/homeCareJobs/stain`;

  it('lets a parent put one up before the job exists', async () => {
    await assertSucceeds(
      upload(await storageOf('parent'), photo(NEW, 'before'), PEOPLE.parent.uid),
    );
  });

  it('refuses anything but a JPEG, anything over 5 MiB, and an unstamped one', async () => {
    const storage = await storageOf('admin');
    const uid = PEOPLE.admin.uid;
    await assertFails(upload(storage, photo(NEW, 'before'), uid, { contentType: 'image/png' }));
    await assertFails(
      upload(storage, photo(NEW, 'before'), uid, { bytes: new Uint8Array(5 * 1024 * 1024 + 1) }),
    );
    await assertFails(upload(storage, photo(NEW, 'before'), PEOPLE.parent.uid));
  });

  it('refuses a name that is neither before nor an after photo', async () => {
    await assertFails(upload(await storageOf('admin'), photo(NEW, 'selfie'), PEOPLE.admin.uid));
  });

  it('denies the cleaner and the look-only helper', async () => {
    await assertFails(upload(await storageOf('cleaner'), photo(NEW, 'before'), PEOPLE.cleaner.uid));
    await assertFails(upload(await storageOf('viewer'), photo(NEW, 'before'), PEOPLE.viewer.uid));
  });

  it('never replaces one that is there', async () => {
    await assertFails(
      upload(await storageOf('admin'), photo(JOBS.cleaners, 'before'), PEOPLE.admin.uid),
    );
  });
});

describe('the after photo', () => {
  it('lets the cleaner hand in hers', async () => {
    await assertSucceeds(
      upload(await storageOf('cleaner'), photo(JOBS.cleaners, 'after-1'), PEOPLE.cleaner.uid),
    );
  });

  it('denies the cleaner an after photo on anybody else’s job', async () => {
    await assertFails(
      upload(await storageOf('cleaner'), photo(JOBS.nobodys, 'after-1'), PEOPLE.cleaner.uid),
    );
  });

  it('lets the look-only helper hand in her own job, and nobody else’s', async () => {
    const storage = await storageOf('viewer');
    await assertSucceeds(upload(storage, photo(JOBS.viewers, 'after-2'), PEOPLE.viewer.uid));
    await assertFails(upload(storage, photo(JOBS.cleaners, 'after-1'), PEOPLE.viewer.uid));
  });

  it('refuses one for a job already handed in', async () => {
    await givenHomeCareRecords({ cleaners: { status: 'submitted', revision: 1 } });
    await assertFails(
      upload(await storageOf('cleaner'), photo(JOBS.cleaners, 'after-2'), PEOPLE.cleaner.uid),
    );
  });

  it('refuses one for a job that does not exist', async () => {
    await assertFails(
      upload(
        await storageOf('admin'),
        photo(`${HOME}/homeCareJobs/ghost`, 'after-1'),
        PEOPLE.admin.uid,
      ),
    );
  });

  it('denies the carer', async () => {
    await assertFails(
      upload(await storageOf('carer'), photo(JOBS.cleaners, 'after-1'), PEOPLE.carer.uid),
    );
  });
});

describe('removing photos', () => {
  it('lets a parent delete a job’s photo', async () => {
    await assertSucceeds(
      deleteObject(ref(await storageOf('parent'), photo(JOBS.cleaners, 'before'))),
    );
  });

  it('denies the cleaner, even on her own job', async () => {
    await assertFails(
      deleteObject(ref(await storageOf('cleaner'), photo(JOBS.cleaners, 'before'))),
    );
  });
});
