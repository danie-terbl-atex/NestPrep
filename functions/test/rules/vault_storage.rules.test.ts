import { doc, setDoc } from 'firebase/firestore';
import { deleteObject, getBytes, listAll, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import {
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

/**
 * Personal vaults, the bytes half (documents ADR-0002, ADR-0003).
 *
 * These rules do not trust the token's `households` claim at all — every
 * decision reads Firestore live, through cross-service rules. So the tests set
 * up Firestore, and several of them hand the caller a *generous* claim on
 * purpose: an admin claim for somebody who is not an admin proves the claim is
 * not what lets anybody in.
 *
 * Reading needs an opening ticket, which only `openVaultDocument` writes after
 * it has logged the view. No ticket, no bytes — whoever you are.
 */

const SAM = 'uid-sam';
const ALEX = 'uid-alex';
const THANDI = 'uid-thandi';
const STRANGER = 'uid-stranger';
const HOUSEHOLD = 'h1';
const H = `households/${HOUSEHOLD}`;
const PDF = new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2d]);
const FORGED_ADMIN_CLAIM = { [HOUSEHOLD]: 'admin' };

function vaultObject(ownerMemberId: string, documentId: string): string {
  return `${H}/vaults/${ownerMemberId}/${documentId}`;
}

async function givenTheParkers(members: Record<string, string>): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, H), { name: 'The Parkers', timeZone: 'Africa/Johannesburg', members });
    for (const [id, claimedBy] of [
      ['m-sam', SAM],
      ['m-alex', ALEX],
      ['m-thandi', THANDI],
      ['m-emma', null],
    ] as const) {
      await setDoc(doc(db, `${H}/members/${id}`), { displayName: id, color: 'violet', claimedBy });
    }
  });
}

const EVERYONE = { [SAM]: 'admin', [ALEX]: 'member', [THANDI]: 'helper' };

async function givenATicket(
  uid: string,
  documentId: string,
  options: { ownerMemberId?: string; expiresInMs?: number } = {},
): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `${H}/vaultOpenings/${uid}_${documentId}`), {
      ownerMemberId: options.ownerMemberId ?? 'm-emma',
      documentId,
      uid,
      expiresAt: new Date(Date.now() + (options.expiresInMs ?? 60_000)),
    });
  });
}

async function givenAnObject(path: string, uploadedByUid: string): Promise<void> {
  await (
    await rulesEnvironment()
  ).withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), path), PDF, {
      contentType: 'application/pdf',
      customMetadata: { uploadedByUid },
    });
  });
}

function upload(
  storage: FirebaseStorage,
  path: string,
  uid: string,
  options: { contentType?: string; bytes?: Uint8Array } = {},
): Promise<unknown> {
  return uploadBytes(ref(storage, path), options.bytes ?? PDF, {
    contentType: options.contentType ?? 'application/pdf',
    customMetadata: { uploadedByUid: uid },
  });
}

describe('a personal vault in Cloud Storage', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers(EVERYONE);
    await givenAnObject(vaultObject('m-emma', 'passport'), SAM);
    await givenAnObject(vaultObject('m-thandi', 'id-card'), THANDI);
  });

  describe('reading — only through a ticket the server wrote', () => {
    it('lets a caller read the document their live ticket names', async () => {
      await givenATicket(SAM, 'passport');
      await assertSucceeds(
        getBytes(ref(await storageAs(SAM, {}), vaultObject('m-emma', 'passport'))),
      );
    });

    it('denies an admin with no ticket — the view log is not optional', async () => {
      await assertFails(
        getBytes(ref(await storageAs(SAM, FORGED_ADMIN_CLAIM), vaultObject('m-emma', 'passport'))),
      );
    });

    it('denies the owner with no ticket, too', async () => {
      await assertFails(
        getBytes(ref(await storageAs(THANDI, {}), vaultObject('m-thandi', 'id-card'))),
      );
    });

    it('denies a ticket that has expired', async () => {
      await givenATicket(SAM, 'passport', { expiresInMs: -1_000 });
      await assertFails(getBytes(ref(await storageAs(SAM, {}), vaultObject('m-emma', 'passport'))));
    });

    it('denies somebody else"s ticket — a ticket is addressed to one uid', async () => {
      await givenATicket(SAM, 'passport');
      await assertFails(
        getBytes(
          ref(await storageAs(THANDI, FORGED_ADMIN_CLAIM), vaultObject('m-emma', 'passport')),
        ),
      );
    });

    it('denies a ticket issued for another vault', async () => {
      await givenATicket(SAM, 'id-card', { ownerMemberId: 'm-emma' });
      await assertFails(
        getBytes(ref(await storageAs(SAM, {}), vaultObject('m-thandi', 'id-card'))),
      );
    });

    it('denies a signed-out caller, and listing a vault at all', async () => {
      await givenATicket(SAM, 'passport');
      await assertFails(
        getBytes(ref(await storageAsSignedOut(), vaultObject('m-emma', 'passport'))),
      );
      await assertFails(listAll(ref(await storageAs(SAM, {}), `${H}/vaults/m-emma`)));
    });
  });

  describe('adding', () => {
    it('lets an owner add to their own vault, and an admin to a child"s', async () => {
      await assertSucceeds(
        upload(await storageAs(THANDI, {}), vaultObject('m-thandi', 'owner-adds'), THANDI),
      );
      await assertSucceeds(
        upload(await storageAs(SAM, {}), vaultObject('m-emma', 'admin-adds'), SAM),
      );
    });

    it('denies a helper adding to a child"s vault, whatever her token claims', async () => {
      await assertFails(
        upload(
          await storageAs(THANDI, FORGED_ADMIN_CLAIM),
          vaultObject('m-emma', 'helper-adds'),
          THANDI,
        ),
      );
    });

    it('lets a family member who is not an admin file a child"s papers', async () => {
      // `member` is read as `parent` (household ADR-0003): family.
      await assertSucceeds(
        upload(await storageAs(ALEX, {}), vaultObject('m-emma', 'member-adds'), ALEX),
      );
    });

    it('denies a helper adding to an adult"s vault', async () => {
      await assertFails(
        upload(await storageAs(THANDI, {}), vaultObject('m-alex', 'helper-adds-adult'), THANDI),
      );
    });

    it('denies a stranger, and an owner who has since been removed', async () => {
      await assertFails(
        upload(
          await storageAs(STRANGER, FORGED_ADMIN_CLAIM),
          vaultObject('m-emma', 'stranger-adds'),
          STRANGER,
        ),
      );
      await givenTheParkers({ [SAM]: 'admin', [ALEX]: 'member' });
      await assertFails(
        upload(await storageAs(THANDI, {}), vaultObject('m-thandi', 'removed-adds'), THANDI),
      );
    });

    it('holds the same size, type and stamp limits as the household"s documents', async () => {
      const sam = await storageAs(SAM, {});
      const cap = 20 * 1024 * 1024;
      await assertFails(
        upload(sam, vaultObject('m-emma', 'big'), SAM, { bytes: new Uint8Array(cap + 1) }),
      );
      await assertFails(
        upload(sam, vaultObject('m-emma', 'zip'), SAM, { contentType: 'application/zip' }),
      );
      await assertFails(upload(sam, vaultObject('m-emma', 'stamp'), THANDI));
      await assertSucceeds(
        upload(sam, vaultObject('m-emma', 'scan'), SAM, { contentType: 'image/jpeg' }),
      );
    });

    it('denies overwriting a vault object that is already there', async () => {
      await assertFails(upload(await storageAs(SAM, {}), vaultObject('m-emma', 'passport'), SAM));
    });
  });

  describe('deleting', () => {
    it('lets the owner delete from their own vault', async () => {
      await assertSucceeds(
        deleteObject(ref(await storageAs(THANDI, {}), vaultObject('m-thandi', 'id-card'))),
      );
    });

    it('lets an admin delete from a child"s', async () => {
      await assertSucceeds(
        deleteObject(ref(await storageAs(SAM, {}), vaultObject('m-emma', 'passport'))),
      );
    });

    it('denies a helper deleting a child"s passport, even holding a ticket', async () => {
      await givenATicket(THANDI, 'passport');
      await assertFails(
        deleteObject(
          ref(await storageAs(THANDI, FORGED_ADMIN_CLAIM), vaultObject('m-emma', 'passport')),
        ),
      );
    });
  });
});
