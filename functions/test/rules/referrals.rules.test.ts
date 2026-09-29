import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { afterAll, beforeEach, describe, it } from 'vitest';

import {
  HOUSEHOLD,
  KID,
  KID_TABLET,
  MIA,
  NOMSA,
  OLIVIA,
  SAM,
  STRANGER,
  THANDI,
  givenTheParkers,
} from './family_fixture';
import {
  asKid,
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  closeRulesEnvironment,
  givenData,
} from './rules_harness';

/**
 * Referrals — give a month, get a month (subscriptions ADR-0002) — and the V2
 * switches they are turned on by (foundation ADR-0014). The point is the
 * denials: **no phone can give its household a month**, pick its own code,
 * move a referral along, or look up another household through the ledger.
 */
const OWN = `households/${HOUSEHOLD}/referral/current`;
const HISTORY = `households/${HOUSEHOLD}/referralHistory`;
const LINE = `households/${HOUSEHOLD}/referralHistory/line-1`;
const GRANTS = `households/${HOUSEHOLD}/premiumGrants`;
const GRANT = `households/${HOUSEHOLD}/premiumGrants/referral-line-1`;
const CODE = 'referralCodes/ABCD2345';
const LEDGER = `referrals/${HOUSEHOLD}`;
const FLAGS = 'appConfig/flags';

const now = Timestamp.now();

async function givenAReferral(): Promise<void> {
  await givenData(async (db) => {
    await setDoc(doc(db, OWN), { code: 'ABCD2345', redeemBy: null, hasRedeemed: false });
    await setDoc(doc(db, LINE), {
      side: 'referrer',
      status: 'qualified',
      redeemedAt: now,
      qualifyBy: now,
      qualifiedAt: now,
      reward: 'month',
    });
    await setDoc(doc(db, GRANT), { source: 'referral', days: 30, grantedAt: now, startsAt: now });
    await setDoc(doc(db, CODE), { householdId: HOUSEHOLD, createdAt: now });
    await setDoc(doc(db, LEDGER), { referrerHouseholdId: 'h2', status: 'pending' });
    await setDoc(doc(db, FLAGS), { referralRewards: true });
  });
}

afterAll(closeRulesEnvironment);

describe('a household’s referral code, history and granted months', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
    await givenAReferral();
  });

  it('are read by family — the admin and a parent', async () => {
    for (const uid of [SAM, MIA]) {
      const db = await asUser(uid);
      await assertSucceeds(getDoc(doc(db, OWN)));
      await assertSucceeds(getDocs(collection(db, HISTORY)));
      await assertSucceeds(getDocs(collection(db, GRANTS)));
    }
  });

  it('are not read by a helper, a carer or a kid’s tablet — referring is the family’s', async () => {
    for (const uid of [THANDI, NOMSA]) {
      const db = await asUser(uid);
      await assertFails(getDoc(doc(db, OWN)));
      await assertFails(getDocs(collection(db, HISTORY)));
      await assertFails(getDoc(doc(db, GRANT)));
    }
    const tablet = await asKid(KID_TABLET, { householdId: HOUSEHOLD, memberId: KID });
    await assertFails(getDoc(doc(tablet, OWN)));
    await assertFails(getDocs(collection(tablet, HISTORY)));
  });

  it('are not read by another household’s admin, a stranger or nobody', async () => {
    for (const db of [await asUser(OLIVIA), await asUser(STRANGER), await asSignedOut()]) {
      await assertFails(getDoc(doc(db, OWN)));
      await assertFails(getDoc(doc(db, LINE)));
      await assertFails(getDoc(doc(db, GRANT)));
    }
  });

  it('are never written from a phone, not even by the admin — no household gives itself a month', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, OWN), { code: 'MYOWNCODE' }));
    await assertFails(updateDoc(doc(sam, OWN), { hasRedeemed: false }));
    await assertFails(deleteDoc(doc(sam, OWN)));
    await assertFails(updateDoc(doc(sam, LINE), { status: 'qualified', reward: 'month' }));
    await assertFails(setDoc(doc(sam, `${HISTORY}/line-2`), { status: 'qualified' }));
    await assertFails(deleteDoc(doc(sam, LINE)));
    await assertFails(
      setDoc(doc(sam, `${GRANTS}/free`), {
        source: 'referral',
        days: 365,
        grantedAt: now,
        startsAt: now,
      }),
    );
    await assertFails(updateDoc(doc(sam, GRANT), { days: 3650 }));
    await assertFails(deleteDoc(doc(sam, GRANT)));
  });
});

describe('the code index and the referral ledger', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
    await givenAReferral();
  });

  it('are read by nobody — a code cannot be looked up, nor the ledger walked', async () => {
    for (const db of [await asUser(SAM), await asUser(STRANGER), await asSignedOut()]) {
      await assertFails(getDoc(doc(db, CODE)));
      await assertFails(getDocs(collection(db, 'referralCodes')));
      await assertFails(getDoc(doc(db, LEDGER)));
      await assertFails(getDocs(collection(db, 'referrals')));
    }
  });

  it('are written by nobody — no phone picks a code or moves a referral along', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, 'referralCodes/MINEMINE'), { householdId: HOUSEHOLD }));
    await assertFails(updateDoc(doc(sam, CODE), { householdId: 'h2' }));
    await assertFails(deleteDoc(doc(sam, CODE)));
    await assertFails(updateDoc(doc(sam, LEDGER), { status: 'qualified' }));
    await assertFails(setDoc(doc(sam, 'referrals/h9'), { referrerHouseholdId: HOUSEHOLD }));
    await assertFails(deleteDoc(doc(sam, LEDGER)));
  });
});

describe('appConfig — the V2 switches (foundation ADR-0014)', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
    await givenAReferral();
  });

  it('anybody reads the switches, signed in or not', async () => {
    await assertSucceeds(getDoc(doc(await asUser(STRANGER), FLAGS)));
    await assertSucceeds(getDoc(doc(await asSignedOut(), FLAGS)));
  });

  it('nobody lists the collection or reads another config document', async () => {
    const sam = await asUser(SAM);
    await assertFails(getDocs(collection(sam, 'appConfig')));
    await assertFails(getDoc(doc(sam, 'appConfig/secrets')));
  });

  it('nobody writes a switch from the app, not even an admin', async () => {
    const sam = await asUser(SAM);
    await assertFails(setDoc(doc(sam, FLAGS), { referralRewards: true }));
    await assertFails(updateDoc(doc(sam, FLAGS), { referralRewards: false }));
    await assertFails(deleteDoc(doc(sam, FLAGS)));
  });
});
