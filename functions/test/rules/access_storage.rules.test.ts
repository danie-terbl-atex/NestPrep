import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import { ROLE_DEFAULTS, storageGrant } from '../../src/household/access';
import { CLEANING_ONLY, LOOK_ONLY } from './access_fixture';
import {
  assertFails,
  assertSucceeds,
  clearData,
  rulesEnvironment,
  storageAs,
  type FirebaseStorage,
} from './rules_harness';

/**
 * The bytes half of household ADR-0003. Storage rules cannot read Firestore,
 * so what a kid, helper or carer may open arrives on the token as the `access`
 * claim — built here with the same `storageGrant` the Functions use to write
 * it, so the claim under test is the claim a real account would carry.
 */
const HOUSEHOLD = 'h1';
const PDF = new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2d]);

function pathTo(documentId: string): string {
  return `households/${HOUSEHOLD}/documents/${documentId}`;
}

async function givenAPassport(): Promise<void> {
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), pathTo('passport')), PDF, {
      contentType: 'application/pdf',
      customMetadata: { uploadedByUid: 'uid-thandi' },
    });
  });
}

function upload(storage: FirebaseStorage, id: string, uid: string): Promise<unknown> {
  return uploadBytes(ref(storage, pathTo(id)), PDF, {
    contentType: 'application/pdf',
    customMetadata: { uploadedByUid: uid },
  });
}

describe('documents in Storage, by grant', () => {
  beforeEach(async () => {
    await clearData();
    await givenAPassport();
  });

  it('denies a helper who may only clean the passport, and any upload', async () => {
    const storage = await storageAs(
      'uid-thandi',
      { [HOUSEHOLD]: 'helper' },
      { [HOUSEHOLD]: storageGrant(CLEANING_ONLY) },
    );
    await assertFails(getBytes(ref(storage, pathTo('passport'))));
    await assertFails(upload(storage, 'payslip', 'uid-thandi'));
  });

  it('denies a helper deleting what they uploaded once their documents are gone', async () => {
    const storage = await storageAs(
      'uid-thandi',
      { [HOUSEHOLD]: 'helper' },
      { [HOUSEHOLD]: storageGrant(CLEANING_ONLY) },
    );
    await assertFails(deleteObject(ref(storage, pathTo('passport'))));
  });

  it('lets a helper granted view read the passport, and refuses them an upload', async () => {
    const storage = await storageAs(
      'uid-vera',
      { [HOUSEHOLD]: 'helper' },
      { [HOUSEHOLD]: storageGrant(LOOK_ONLY) },
    );
    await assertSucceeds(getBytes(ref(storage, pathTo('passport'))));
    await assertFails(upload(storage, 'scan', 'uid-vera'));
  });

  it('lets a helper granted edit upload', async () => {
    const storage = await storageAs(
      'uid-vera',
      { [HOUSEHOLD]: 'helper' },
      { [HOUSEHOLD]: { documents: 'edit' } },
    );
    await assertSucceeds(upload(storage, 'scan', 'uid-vera'));
  });

  it('denies a kid and a carer, whose defaults hold no documents', async () => {
    for (const [uid, role] of [
      ['uid-kid', 'kid'],
      ['uid-nomsa', 'carer'],
    ] as const) {
      const storage = await storageAs(
        uid,
        { [HOUSEHOLD]: role },
        { [HOUSEHOLD]: storageGrant(ROLE_DEFAULTS[role]) },
      );
      await assertFails(getBytes(ref(storage, pathTo('passport'))));
    }
  });

  it('lets a parent, and the old `member`, read and upload with no grant at all', async () => {
    for (const role of ['parent', 'member']) {
      const storage = await storageAs('uid-pat', { [HOUSEHOLD]: role }, {});
      await assertSucceeds(getBytes(ref(storage, pathTo('passport'))));
      await assertSucceeds(upload(storage, `from-${role}`, 'uid-pat'));
    }
  });

  it('keeps a helper whose token predates ADR-0003 where every helper was', async () => {
    const storage = await storageAs('uid-old', { [HOUSEHOLD]: 'helper' });
    await assertSucceeds(getBytes(ref(storage, pathTo('passport'))));
  });

  it('but not a kid or a carer on such a token — the new roles start with nothing', async () => {
    for (const role of ['kid', 'carer']) {
      const storage = await storageAs('uid-new', { [HOUSEHOLD]: role });
      await assertFails(getBytes(ref(storage, pathTo('passport'))));
    }
  });

  it('reads a grant for this household only, never one written for another', async () => {
    const storage = await storageAs(
      'uid-vera',
      { [HOUSEHOLD]: 'helper' },
      { 'h-elsewhere': { documents: 'edit' } },
    );
    await assertFails(getBytes(ref(storage, pathTo('passport'))));
  });
});
