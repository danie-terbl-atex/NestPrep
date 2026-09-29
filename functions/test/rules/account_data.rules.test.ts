import { deleteDoc, doc, getDoc, getDocs, collection, setDoc } from 'firebase/firestore';
import { getBytes, listAll, ref, uploadBytes } from 'firebase/storage';
import { beforeEach, describe, it } from 'vitest';

import {
  assertFails,
  assertSucceeds,
  asSignedOut,
  asUser,
  clearData,
  givenData,
  rulesEnvironment,
  storageAsSignedOut,
  storageAsStranger,
} from './rules_harness';

/**
 * Account data (accounts ADR-0006): the erasure ledger, the web deletion
 * requests and the rate-limit windows are the Functions' alone, and an export
 * is readable by its own account and nobody else.
 */

const SAM = 'uid-sam';
const ALEX = 'uid-alex';
const EXPORT = `accountExports/${SAM}/export-1.json`;
const JSON_BYTES = new TextEncoder().encode('{"formatVersion":1}');

beforeEach(async () => {
  await clearData();
});

describe('the Functions-only account-data collections', () => {
  const closed = [
    `accountDeletions/${SAM}`,
    'accountDeletionRequests/request-1',
    'rateLimits/window-1',
  ];

  beforeEach(async () => {
    await givenData(async (db) => {
      for (const path of closed) await setDoc(doc(db, path), { seeded: true });
    });
  });

  for (const path of closed) {
    it(`${path.split('/')[0] ?? path}: nobody reads, writes or deletes one — not even the account it is about`, async () => {
      const sam = await asUser(SAM);
      await assertFails(getDoc(doc(sam, path)));
      await assertFails(setDoc(doc(sam, path), { seeded: false }));
      await assertFails(deleteDoc(doc(sam, path)));
      await assertFails(getDoc(doc(await asSignedOut(), path)));
    });
  }

  it('a signed-in account cannot list the deletion requests, which would be a list of people', async () => {
    await assertFails(getDocs(collection(await asUser(ALEX), 'accountDeletionRequests')));
  });
});

describe('an account data export in Storage', () => {
  beforeEach(async () => {
    await (
      await rulesEnvironment()
    ).withSecurityRulesDisabled(async (context) => {
      await uploadBytes(ref(context.storage(), EXPORT), JSON_BYTES, {
        contentType: 'application/json',
      });
    });
  });

  it('its own account reads it within the hour', async () => {
    await assertSucceeds(getBytes(ref(await storageAsStranger(SAM), EXPORT)));
  });

  it('another account cannot read it', async () => {
    await assertFails(getBytes(ref(await storageAsStranger(ALEX), EXPORT)));
  });

  it('nobody signed out can read it', async () => {
    await assertFails(getBytes(ref(await storageAsSignedOut(), EXPORT)));
  });

  it('its own account cannot list, write or overwrite exports — only the Function writes one', async () => {
    const sam = await storageAsStranger(SAM);
    await assertFails(listAll(ref(sam, `accountExports/${SAM}`)));
    await assertFails(
      uploadBytes(ref(sam, EXPORT), JSON_BYTES, { contentType: 'application/json' }),
    );
    await assertFails(
      uploadBytes(ref(sam, `accountExports/${SAM}/forged.json`), JSON_BYTES, {
        contentType: 'application/json',
      }),
    );
  });
});
