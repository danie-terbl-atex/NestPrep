import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * Personal vaults, the metadata half (documents ADR-0002, ADR-0003).
 *
 * The household below has the four cases the access table turns on: Sam an
 * admin, Alex a member, Thandi a helper, and Emma a child nobody has claimed.
 * Every refusal the phase names is here — above all that **a helper reads no ID
 * copy unless granted it**. The bytes have their own suite,
 * `vault_storage.rules.test.ts`.
 */

const SAM = 'uid-sam';
const ALEX = 'uid-alex';
const THANDI = 'uid-thandi';
const STRANGER = 'uid-stranger';
const H = 'households/h1';
const EMMA_VAULT = `${H}/vaults/m-emma`;
const THANDI_VAULT = `${H}/vaults/m-thandi`;

async function givenTheParkers(): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, H), {
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: { [SAM]: 'admin', [ALEX]: 'member', [THANDI]: 'helper' },
    });
    for (const [id, role, claimedBy] of [
      ['m-sam', 'admin', SAM],
      ['m-alex', 'member', ALEX],
      ['m-thandi', 'helper', THANDI],
      ['m-emma', 'member', null],
    ] as const) {
      await setDoc(doc(db, `${H}/members/${id}`), {
        displayName: id,
        color: 'violet',
        role,
        claimedBy,
      });
    }
    await setDoc(doc(db, `${EMMA_VAULT}/vaultDocuments/passport`), vaultRow('m-sam'));
    await setDoc(doc(db, `${THANDI_VAULT}/vaultDocuments/id-card`), vaultRow('m-thandi'));
    await setDoc(doc(db, `${EMMA_VAULT}/views/v1`), {
      documentId: 'passport',
      documentName: 'Passport',
      viewerMemberId: 'm-sam',
      viewerRole: 'admin',
      viewedAt: new Date(),
    });
    await setDoc(doc(db, `${H}/vaultOpenings/${SAM}_passport`), {
      ownerMemberId: 'm-emma',
      documentId: 'passport',
      uid: SAM,
      expiresAt: new Date(Date.now() + 60_000),
    });
  });
}

function vaultRow(uploadedBy: string): Record<string, unknown> {
  return {
    name: 'Passport',
    contentType: 'application/pdf',
    sizeBytes: 300_000,
    uploadedBy,
    uploadedAt: new Date(),
    tags: ['ID'],
    expiresOn: '2031-04-30',
  };
}

function newRow(uploadedBy: string, extra: Record<string, unknown> = {}): Record<string, unknown> {
  return { ...vaultRow(uploadedBy), uploadedAt: serverTimestamp(), ...extra };
}

async function givenAGrant(vault: string, granteeUid: string, memberId: string): Promise<void> {
  await givenData(async (db: Firestore) => {
    await setDoc(doc(db, `${vault}/grants/${granteeUid}`), {
      memberId,
      grantedBy: 'm-sam',
      grantedAt: new Date(),
    });
  });
}

beforeEach(async () => {
  await clearData();
  await givenTheParkers();
});

describe('vaults/{memberId}/vaultDocuments — reading', () => {
  it('lets an admin read and list a child"s vault', async () => {
    const sam = await asUser(SAM);
    await assertSucceeds(getDoc(doc(sam, `${EMMA_VAULT}/vaultDocuments/passport`)));
    await assertSucceeds(getDocs(collection(sam, `${EMMA_VAULT}/vaultDocuments`)));
  });

  it('lets an owner read their own vault — a helper included', async () => {
    const thandi = await asUser(THANDI);
    await assertSucceeds(getDoc(doc(thandi, `${THANDI_VAULT}/vaultDocuments/id-card`)));
    await assertSucceeds(getDocs(collection(thandi, `${THANDI_VAULT}/vaultDocuments`)));
  });

  it('denies a helper reading a child"s ID copy that nobody granted her', async () => {
    const thandi = await asUser(THANDI);
    await assertFails(getDoc(doc(thandi, `${EMMA_VAULT}/vaultDocuments/passport`)));
    await assertFails(getDocs(collection(thandi, `${EMMA_VAULT}/vaultDocuments`)));
  });

  it('lets a family member who is not an admin read every vault (household ADR-0003)', async () => {
    // `member` is read as `parent`: family, and per-item privacy between
    // family members is out of v1.
    const alex = await asUser(ALEX);
    await assertSucceeds(getDoc(doc(alex, `${THANDI_VAULT}/vaultDocuments/id-card`)));
    await assertSucceeds(getDocs(collection(alex, `${EMMA_VAULT}/vaultDocuments`)));
  });

  it('denies a helper reading an adult"s vault nobody shared with her', async () => {
    await assertFails(
      getDocs(collection(await asUser(THANDI), `${H}/vaults/m-alex/vaultDocuments`)),
    );
  });

  it('lets a helper read it once granted — and only read', async () => {
    await givenAGrant(EMMA_VAULT, THANDI, 'm-thandi');
    const thandi = await asUser(THANDI);
    await assertSucceeds(getDoc(doc(thandi, `${EMMA_VAULT}/vaultDocuments/passport`)));
    await assertSucceeds(getDocs(collection(thandi, `${EMMA_VAULT}/vaultDocuments`)));
    await assertFails(
      updateDoc(doc(thandi, `${EMMA_VAULT}/vaultDocuments/passport`), { name: 'Old passport' }),
    );
    await assertFails(deleteDoc(doc(thandi, `${EMMA_VAULT}/vaultDocuments/passport`)));
  });

  it('denies an owner who has been removed from the household', async () => {
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, H), {
        name: 'The Parkers',
        timeZone: 'Africa/Johannesburg',
        members: { [SAM]: 'admin', [ALEX]: 'member' },
      });
    });
    await assertFails(getDoc(doc(await asUser(THANDI), `${THANDI_VAULT}/vaultDocuments/id-card`)));
  });

  it('denies a stranger and a signed-out caller', async () => {
    await assertFails(getDoc(doc(await asUser(STRANGER), `${EMMA_VAULT}/vaultDocuments/passport`)));
    await assertFails(getDoc(doc(await asSignedOut(), `${EMMA_VAULT}/vaultDocuments/passport`)));
  });
});

describe('vaults/{memberId}/vaultDocuments — writing', () => {
  it('lets an owner add to their own vault, and an admin to a child"s', async () => {
    await assertSucceeds(
      setDoc(doc(await asUser(THANDI), `${THANDI_VAULT}/vaultDocuments/new`), newRow('m-thandi')),
    );
    await assertSucceeds(
      setDoc(doc(await asUser(SAM), `${EMMA_VAULT}/vaultDocuments/new`), newRow('m-sam')),
    );
  });

  it('denies a helper adding to somebody else"s vault, granted or not', async () => {
    await givenAGrant(EMMA_VAULT, THANDI, 'm-thandi');
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${EMMA_VAULT}/vaultDocuments/new`), newRow('m-thandi')),
    );
  });

  it('denies a row in somebody else"s name, or with a time the client chose', async () => {
    const thandi = await asUser(THANDI);
    await assertFails(setDoc(doc(thandi, `${THANDI_VAULT}/vaultDocuments/new`), newRow('m-sam')));
    await assertFails(
      setDoc(doc(thandi, `${THANDI_VAULT}/vaultDocuments/new`), {
        ...newRow('m-thandi'),
        uploadedAt: new Date(),
      }),
    );
  });

  it('denies a field the rules do not name', async () => {
    await assertFails(
      setDoc(
        doc(await asUser(SAM), `${EMMA_VAULT}/vaultDocuments/new`),
        newRow('m-sam', { ownerMemberId: 'm-sam' }),
      ),
    );
  });

  it('allows no tags and no expiry at all', async () => {
    const row = newRow('m-sam');
    delete row['tags'];
    delete row['expiresOn'];
    await assertSucceeds(setDoc(doc(await asUser(SAM), `${EMMA_VAULT}/vaultDocuments/new`), row));
  });

  it('denies a ninth tag, an empty tag and a tag past 24 characters', async () => {
    const sam = await asUser(SAM);
    const path = `${EMMA_VAULT}/vaultDocuments/new`;
    const nine = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'];
    await assertFails(setDoc(doc(sam, path), newRow('m-sam', { tags: nine })));
    await assertFails(setDoc(doc(sam, path), newRow('m-sam', { tags: ['ok', ''] })));
    await assertFails(setDoc(doc(sam, path), newRow('m-sam', { tags: ['x'.repeat(25)] })));
    await assertSucceeds(setDoc(doc(sam, path), newRow('m-sam', { tags: nine.slice(0, 8) })));
  });

  it('denies an expiry that is not a calendar-shaped day', async () => {
    const sam = await asUser(SAM);
    const path = `${EMMA_VAULT}/vaultDocuments/new`;
    await assertFails(setDoc(doc(sam, path), newRow('m-sam', { expiresOn: '30/04/2031' })));
    await assertFails(setDoc(doc(sam, path), newRow('m-sam', { expiresOn: '2031-13-01' })));
    await assertFails(setDoc(doc(sam, path), newRow('m-sam', { expiresOn: new Date() })));
  });

  it('lets an owner rename, tag and date a document, and nothing else', async () => {
    const thandi = await asUser(THANDI);
    const path = `${THANDI_VAULT}/vaultDocuments/id-card`;
    await assertSucceeds(
      updateDoc(doc(thandi, path), { name: 'ID', tags: ['id', 'work'], expiresOn: null }),
    );
    await assertFails(updateDoc(doc(thandi, path), { sizeBytes: 1 }));
    await assertFails(updateDoc(doc(thandi, path), { contentType: 'image/png' }));
  });

  it('lets an owner or the family delete, and denies a helper who is neither', async () => {
    await assertFails(
      deleteDoc(doc(await asUser(THANDI), `${EMMA_VAULT}/vaultDocuments/passport`)),
    );
    await assertSucceeds(
      deleteDoc(doc(await asUser(ALEX), `${EMMA_VAULT}/vaultDocuments/passport`)),
    );
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, `${EMMA_VAULT}/vaultDocuments/passport`), vaultRow('m-sam'));
    });
    await assertSucceeds(
      deleteDoc(doc(await asUser(SAM), `${THANDI_VAULT}/vaultDocuments/id-card`)),
    );
    await assertSucceeds(
      deleteDoc(doc(await asUser(SAM), `${EMMA_VAULT}/vaultDocuments/passport`)),
    );
  });
});

describe('vaults/{memberId}/grants/{granteeUid}', () => {
  const grant = (memberId: string, grantedBy = 'm-sam'): Record<string, unknown> => ({
    memberId,
    grantedBy,
    grantedAt: serverTimestamp(),
  });

  it('lets an admin grant a helper a child"s vault', async () => {
    await assertSucceeds(
      setDoc(doc(await asUser(SAM), `${EMMA_VAULT}/grants/${THANDI}`), grant('m-thandi')),
    );
  });

  it('lets an owner share their own vault', async () => {
    await assertSucceeds(
      setDoc(
        doc(await asUser(THANDI), `${THANDI_VAULT}/grants/${ALEX}`),
        grant('m-alex', 'm-thandi'),
      ),
    );
  });

  it('denies a helper granting herself somebody else"s vault', async () => {
    await assertFails(
      setDoc(
        doc(await asUser(THANDI), `${EMMA_VAULT}/grants/${THANDI}`),
        grant('m-thandi', 'm-thandi'),
      ),
    );
  });

  it('denies a grant whose uid is not the claimant of the profile it names', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), `${EMMA_VAULT}/grants/${ALEX}`), grant('m-thandi')),
    );
  });

  it('denies a grant to somebody outside the household', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), `${EMMA_VAULT}/grants/${STRANGER}`), grant('m-thandi')),
    );
  });

  it('denies granting a vault to its own owner, and changing a grant', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), `${THANDI_VAULT}/grants/${THANDI}`), grant('m-thandi')),
    );
    await givenAGrant(EMMA_VAULT, THANDI, 'm-thandi');
    await assertFails(
      updateDoc(doc(await asUser(SAM), `${EMMA_VAULT}/grants/${THANDI}`), { memberId: 'm-alex' }),
    );
  });

  it('lets a grantee see the grant addressed to them, and nobody else"s', async () => {
    await givenAGrant(EMMA_VAULT, THANDI, 'm-thandi');
    await givenAGrant(EMMA_VAULT, ALEX, 'm-alex');
    const thandi = await asUser(THANDI);
    await assertSucceeds(getDoc(doc(thandi, `${EMMA_VAULT}/grants/${THANDI}`)));
    await assertFails(getDoc(doc(thandi, `${EMMA_VAULT}/grants/${ALEX}`)));
    await assertFails(getDocs(collection(thandi, `${EMMA_VAULT}/grants`)));
  });

  it('lets an admin revoke a grant, and denies the grantee revoking it', async () => {
    await givenAGrant(EMMA_VAULT, THANDI, 'm-thandi');
    await assertFails(deleteDoc(doc(await asUser(THANDI), `${EMMA_VAULT}/grants/${THANDI}`)));
    await assertSucceeds(deleteDoc(doc(await asUser(SAM), `${EMMA_VAULT}/grants/${THANDI}`)));
  });
});

describe('vaults/{memberId}/views — the view log', () => {
  it('lets the family read every vault"s log', async () => {
    await assertSucceeds(getDocs(collection(await asUser(SAM), `${EMMA_VAULT}/views`)));
    await assertSucceeds(getDocs(collection(await asUser(ALEX), `${THANDI_VAULT}/views`)));
  });

  it('lets an owner read their own vault"s log', async () => {
    await assertSucceeds(getDocs(collection(await asUser(THANDI), `${THANDI_VAULT}/views`)));
  });

  it('denies a helper, even one granted the vault, reading its log', async () => {
    await givenAGrant(EMMA_VAULT, THANDI, 'm-thandi');
    await assertFails(getDocs(collection(await asUser(THANDI), `${EMMA_VAULT}/views`)));
  });

  it('denies every client writing, editing or deleting an entry — admins too', async () => {
    const sam = await asUser(SAM);
    await assertFails(
      setDoc(doc(sam, `${EMMA_VAULT}/views/forged`), {
        documentId: 'passport',
        documentName: 'Passport',
        viewerMemberId: 'm-alex',
        viewerRole: 'member',
        viewedAt: serverTimestamp(),
      }),
    );
    await assertFails(updateDoc(doc(sam, `${EMMA_VAULT}/views/v1`), { viewerMemberId: 'm-alex' }));
    await assertFails(deleteDoc(doc(sam, `${EMMA_VAULT}/views/v1`)));
  });
});

describe('what only the server writes', () => {
  it('denies every client an opening ticket — reading one or forging one', async () => {
    const sam = await asUser(SAM);
    await assertFails(getDoc(doc(sam, `${H}/vaultOpenings/${SAM}_passport`)));
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${H}/vaultOpenings/${THANDI}_passport`), {
        ownerMemberId: 'm-emma',
        documentId: 'passport',
        uid: THANDI,
        expiresAt: new Date(Date.now() + 60_000),
      }),
    );
  });

  it('denies every client the expiry reminders notifications will deliver', async () => {
    const sam = await asUser(SAM);
    await assertFails(getDocs(collection(sam, `${H}/expiryReminders`)));
    await assertFails(
      setDoc(doc(sam, `${H}/expiryReminders/r1`), { status: 'sent', documentId: 'passport' }),
    );
  });
});

describe('household documents gain tags and an expiry (documents ADR-0005)', () => {
  beforeEach(async () => {
    await givenData(async (db: Firestore) => {
      await setDoc(doc(db, `${H}/documents/policy`), {
        folderId: 'insurance',
        name: 'Car insurance',
        contentType: 'application/pdf',
        sizeBytes: 200_000,
        uploadedBy: 'm-thandi',
        uploadedAt: new Date(),
      });
    });
  });

  it('lets a member add one with tags and an expiry date', async () => {
    await assertSucceeds(
      setDoc(doc(await asUser(ALEX), `${H}/documents/new`), {
        folderId: 'insurance',
        name: 'House insurance',
        contentType: 'application/pdf',
        sizeBytes: 200_000,
        uploadedBy: 'm-alex',
        uploadedAt: serverTimestamp(),
        tags: ['insurance'],
        expiresOn: '2027-03-01',
      }),
    );
  });

  it('lets the uploader tag and date a row written before the fields existed', async () => {
    await assertSucceeds(
      updateDoc(doc(await asUser(THANDI), `${H}/documents/policy`), {
        tags: ['car', 'renew'],
        expiresOn: '2027-01-31',
      }),
    );
  });

  it('denies a malformed expiry or too many tags there too', async () => {
    const thandi = await asUser(THANDI);
    await assertFails(updateDoc(doc(thandi, `${H}/documents/policy`), { expiresOn: 'next March' }));
    await assertFails(
      updateDoc(doc(thandi, `${H}/documents/policy`), {
        tags: ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
      }),
    );
  });
});
