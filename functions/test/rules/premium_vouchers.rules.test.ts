import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  collection,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { afterAll, beforeEach, describe, it } from 'vitest';

import { HOUSEHOLD, MIA, OLIVIA, SAM, STRANGER, givenTheParkers } from './family_fixture';
import {
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  closeRulesEnvironment,
  givenData,
  type Firestore,
} from './rules_harness';

const VOUCHER = 'premiumVouchers/order-1_1';
const CODE = 'premiumCodes/code-hash';
const CLAIM = `premiumCodes/code-hash/claims/${HOUSEHOLD}`;
const REDEMPTION = 'premiumCodes/code-hash/redemptions/email-hash';
const CHALLENGE = `premiumEmailChallenges/${SAM}`;
const VERIFIED = `users/${SAM}/private/verifiedEmails`;
const ACQUISITION = `households/${HOUSEHOLD}/private/acquisition`;
const ENTITLEMENT = `households/${HOUSEHOLD}/entitlement/current`;

const SERVER_ONLY = [VOUCHER, CODE, CLAIM, REDEMPTION, CHALLENGE, VERIFIED, ACQUISITION];

const now = Timestamp.now();

async function givenPremiumVouchers(): Promise<void> {
  await givenData(async (db) => {
    await setDoc(doc(db, VOUCHER), {
      kind: 'frame',
      emailHash: 'email-hash',
      emailMasked: 's***@example.com',
      status: 'waiting',
      days: 93,
      isTest: false,
    });
    await setDoc(doc(db, CODE), { shape: 'shared', label: 'Launch', days: 30, claimCount: 0 });
    await setDoc(doc(db, CLAIM), { uid: SAM, voucherId: 'v1', at: now });
    await setDoc(doc(db, REDEMPTION), { voucherId: 'v1', at: now });
    await setDoc(doc(db, CHALLENGE), { emailHash: 'email-hash', codeHash: 'x', tries: 0 });
    await setDoc(doc(db, VERIFIED), { emails: { 'email-hash': { via: 'code' } } });
    await setDoc(doc(db, ACQUISITION), { code: 'THANDI10', partnerId: 'p1', via: 'frame-order' });
    await setDoc(doc(db, ENTITLEMENT), { premiumUntil: now, grantDaysWaiting: { frame: 93 } });
  });
}

async function everyoneAsking(): Promise<[string, Firestore][]> {
  return [
    ['the account itself, admin of the household', await asUser(SAM)],
    ['a parent in the household', await asUser(MIA)],
    ['another household’s admin', await asUser(OLIVIA)],
    ['a stranger', await asUser(STRANGER)],
    ['nobody signed in', await asSignedOut()],
  ];
}

afterAll(closeRulesEnvironment);

describe('Premium vouchers, codes, email proofs and acquisition', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
    await givenPremiumVouchers();
  });

  it('leave the household’s entitlement readable, as before', async () => {
    await assertSucceeds(getDoc(doc(await asUser(SAM), ENTITLEMENT)));
  });

  it('are read by nobody — not even the account or household they are about', async () => {
    for (const [who, db] of await everyoneAsking()) {
      for (const path of SERVER_ONLY)
        await assertFails(getDoc(doc(db, path))).catch(rethrowAs(who, path));
    }
  });

  it('cannot be listed from a phone', async () => {
    for (const [, db] of await everyoneAsking()) {
      await assertFails(getDocs(collection(db, 'premiumVouchers')));
      await assertFails(getDocs(collection(db, 'premiumCodes')));
      await assertFails(getDocs(collection(db, 'premiumCodes/code-hash/claims')));
      await assertFails(getDocs(collection(db, 'premiumCodes/code-hash/redemptions')));
      await assertFails(getDocs(collection(db, 'premiumEmailChallenges')));
      await assertFails(getDocs(collection(db, `users/${SAM}/private`)));
      await assertFails(getDocs(collection(db, `households/${HOUSEHOLD}/private`)));
    }
  });

  it('are never written from a phone — no account gives itself Premium or a proven email', async () => {
    for (const [who, db] of await everyoneAsking()) {
      for (const path of SERVER_ONLY) {
        await assertFails(setDoc(doc(db, path), { status: 'claimed' })).catch(rethrowAs(who, path));
        await assertFails(updateDoc(doc(db, path), { days: 3650 })).catch(rethrowAs(who, path));
        await assertFails(deleteDoc(doc(db, path))).catch(rethrowAs(who, path));
      }
      await assertFails(setDoc(doc(db, 'premiumVouchers/new-one'), { kind: 'frame' }));
      await assertFails(setDoc(doc(db, 'premiumCodes/new-code'), { days: 365 }));
      await assertFails(setDoc(doc(db, `users/${SAM}/private/anything`), { x: 1 }));
      await assertFails(setDoc(doc(db, `households/${HOUSEHOLD}/private/anything`), { x: 1 }));
    }
  });
});

function rethrowAs(who: string, path: string): (error: unknown) => never {
  return (error) => {
    throw new Error(`${who} on ${path}: ${error instanceof Error ? error.message : String(error)}`);
  };
}
