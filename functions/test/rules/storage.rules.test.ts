import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

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
 * The bytes half of the documents feature (documents ADR-0001).
 *
 * Storage Security Rules cannot read Firestore. Everything the Firestore rules
 * answer with a `get()` on the household's uid→role map has to arrive here on
 * the caller's token instead, as the `households` claim that
 * `syncDocumentAccess` writes. So every test below says what is on the token,
 * and the interesting ones say the wrong thing on purpose: a claim for another
 * household, a claim that is not there at all, a member claim where the rule
 * wants an admin.
 *
 * Two rules live only here and nowhere else that counts — the 20 MiB cap and
 * the list of types a household may keep. The client refuses earlier so nobody
 * waits for a refusal, but that check is a courtesy and this one is the rule
 * (FE-04, BE-20).
 */

const SAM = 'uid-sam';
const THANDI = 'uid-thandi';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const OTHER_HOUSEHOLD = 'h2';

const AS_ADMIN = { [HOUSEHOLD]: 'admin' };
const AS_HELPER = { [HOUSEHOLD]: 'helper' };
const AS_MEMBER_ELSEWHERE = { [OTHER_HOUSEHOLD]: 'admin' };

/** The object's name is its metadata document's id (documents ADR-0001). */
function pathTo(documentId: string, householdId = HOUSEHOLD): string {
  return `households/${householdId}/documents/${documentId}`;
}

const PDF = new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2d]);

function ofSize(bytes: number): Uint8Array {
  return new Uint8Array(bytes);
}

/** Puts an object there with the rules switched off, stamped with an uploader. */
async function givenAnObject(documentId: string, uploadedByUid: string): Promise<void> {
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), pathTo(documentId)), PDF, {
      contentType: 'application/pdf',
      customMetadata: { uploadedByUid },
    });
  });
}

function upload(
  storage: FirebaseStorage,
  documentId: string,
  options: { uid: string; contentType?: string; bytes?: Uint8Array; householdId?: string },
): Promise<unknown> {
  return uploadBytes(
    ref(storage, pathTo(documentId, options.householdId ?? HOUSEHOLD)),
    options.bytes ?? PDF,
    {
      contentType: options.contentType ?? 'application/pdf',
      customMetadata: { uploadedByUid: options.uid },
    },
  );
}

describe("a household's documents in Cloud Storage", () => {
  beforeEach(async () => {
    await clearData();
    await givenAnObject('letter', THANDI);
  });

  describe('reading', () => {
    it('lets everybody in the household read everything in it', async () => {
      await assertSucceeds(getBytes(ref(await storageAs(SAM, AS_ADMIN), pathTo('letter'))));
      await assertSucceeds(getBytes(ref(await storageAs(THANDI, AS_HELPER), pathTo('letter'))));
    });

    it('denies a signed-in caller whose token carries no household at all', async () => {
      await assertFails(getBytes(ref(await storageAsStranger(STRANGER), pathTo('letter'))));
    });

    it('denies a caller whose token carries a different household', async () => {
      // The whole point of the claim: the path is not the proof.
      await assertFails(
        getBytes(ref(await storageAs(STRANGER, AS_MEMBER_ELSEWHERE), pathTo('letter'))),
      );
    });

    it('denies a signed-out caller', async () => {
      await assertFails(getBytes(ref(await storageAsSignedOut(), pathTo('letter'))));
    });
  });

  describe('adding', () => {
    it('lets any member add a document', async () => {
      await assertSucceeds(upload(await storageAs(THANDI, AS_HELPER), 'report', { uid: THANDI }));
    });

    it('denies a caller with no claim for this household', async () => {
      await assertFails(upload(await storageAsStranger(STRANGER), 'report', { uid: STRANGER }));
      await assertFails(
        upload(await storageAs(STRANGER, AS_MEMBER_ELSEWHERE), 'report', { uid: STRANGER }),
      );
    });

    it('denies an object stamped with somebody else"s uid', async () => {
      // The stamp is what lets the delete rule below agree with the Firestore
      // rule on the metadata row of the same name.
      await assertFails(upload(await storageAs(THANDI, AS_HELPER), 'report', { uid: SAM }));
    });

    it('denies an object with no stamp at all', async () => {
      await assertFails(
        uploadBytes(ref(await storageAs(THANDI, AS_HELPER), pathTo('report')), PDF, {
          contentType: 'application/pdf',
        }),
      );
    });

    it('keeps every type a household actually files', async () => {
      const storage = await storageAs(THANDI, AS_HELPER);
      for (const contentType of [
        'application/pdf',
        'image/jpeg',
        'image/png',
        'image/heic',
        'image/webp',
      ]) {
        await assertSucceeds(
          upload(storage, `ok-${contentType.replace('/', '-')}`, { uid: THANDI, contentType }),
        );
      }
    });

    it('denies a type it does not keep', async () => {
      const storage = await storageAs(THANDI, AS_HELPER);
      for (const contentType of [
        'application/zip',
        'text/html',
        'application/octet-stream',
        'video/mp4',
      ]) {
        await assertFails(
          upload(storage, `no-${contentType.replace('/', '-')}`, { uid: THANDI, contentType }),
        );
      }
    });

    it('denies anything past the cap, and allows what is exactly on it', async () => {
      const storage = await storageAs(THANDI, AS_HELPER);
      const cap = 20 * 1024 * 1024;
      await assertSucceeds(upload(storage, 'at-the-cap', { uid: THANDI, bytes: ofSize(cap) }));
      await assertFails(upload(storage, 'over-the-cap', { uid: THANDI, bytes: ofSize(cap + 1) }));
    });

    it('denies writing anywhere but a household"s documents', async () => {
      const storage = await storageAs(THANDI, AS_HELPER);
      for (const path of [
        'letter.pdf',
        `households/${HOUSEHOLD}/letter.pdf`,
        `households/${HOUSEHOLD}/documents/nested/letter.pdf`,
        `households/${HOUSEHOLD}/members/${THANDI}`,
      ]) {
        await assertFails(
          uploadBytes(ref(storage, path), PDF, {
            contentType: 'application/pdf',
            customMetadata: { uploadedByUid: THANDI },
          }),
        );
      }
    });

    it('denies overwriting bytes that are already there', async () => {
      // A document's bytes never change: replacing one is a delete and an add,
      // so what is in the object stays answerable from the row of the same name.
      await assertFails(upload(await storageAs(THANDI, AS_HELPER), 'letter', { uid: THANDI }));
      await assertFails(upload(await storageAs(SAM, AS_ADMIN), 'letter', { uid: SAM }));
    });
  });

  describe('deleting', () => {
    it('lets the uploader delete their own', async () => {
      await assertSucceeds(deleteObject(ref(await storageAs(THANDI, AS_HELPER), pathTo('letter'))));
    });

    it('lets an admin delete somebody else"s', async () => {
      await assertSucceeds(deleteObject(ref(await storageAs(SAM, AS_ADMIN), pathTo('letter'))));
    });

    it('denies a member who is neither', async () => {
      await assertFails(
        deleteObject(ref(await storageAs('uid-kim', { [HOUSEHOLD]: 'member' }), pathTo('letter'))),
      );
    });

    it('denies a stranger', async () => {
      await assertFails(deleteObject(ref(await storageAsStranger(STRANGER), pathTo('letter'))));
    });
  });
});
