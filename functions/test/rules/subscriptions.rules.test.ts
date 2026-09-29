import { Timestamp, deleteDoc, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { afterAll, beforeEach, describe, it } from 'vitest';

import {
  HOUSEHOLD,
  KID,
  KID_TABLET,
  MIA,
  NOMSA,
  OLIVIA,
  PROFILES,
  SAM,
  STRANGER,
  THANDI,
  THANDI_MEMBER,
  givenTheKidsDetails,
  givenTheParkers,
  merge,
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
 * Subscriptions (subscriptions ADR-0001). The point of this file is the
 * denials: **no client can give itself premium** — not by writing the
 * entitlement, not by reading or writing the store purchases behind it, and
 * not by marking a second child itself, which is what the free tier counts.
 */
const ENTITLEMENT = `households/${HOUSEHOLD}/entitlement/current`;
const PURCHASE = 'storePurchases/abc123';

function premiumFor(days: number): Record<string, unknown> {
  return {
    premiumUntil: Timestamp.fromMillis(Date.now() + days * 24 * 60 * 60 * 1000),
    status: 'active',
    plan: 'yearly',
    store: 'playStore',
    willRenew: true,
    managedByMemberId: 'm-sam',
    isTest: false,
  };
}

async function givenPremium(): Promise<void> {
  await givenData(async (db) => {
    await setDoc(doc(db, ENTITLEMENT), premiumFor(30));
    await setDoc(doc(db, PURCHASE), { householdId: HOUSEHOLD, storeRef: 'purchase-token' });
  });
}

afterAll(closeRulesEnvironment);

describe('the household entitlement', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
    await givenPremium();
  });

  it('is read by everybody in the household — admin, parent, helper, carer and a kid’s tablet', async () => {
    for (const uid of [SAM, MIA, THANDI, NOMSA]) {
      await assertSucceeds(getDoc(doc(await asUser(uid), ENTITLEMENT)));
    }
    await assertSucceeds(
      getDoc(doc(await asKid(KID_TABLET, { householdId: HOUSEHOLD, memberId: KID }), ENTITLEMENT)),
    );
  });

  it('is not read by somebody outside the household, another admin, or nobody', async () => {
    await assertFails(getDoc(doc(await asUser(STRANGER), ENTITLEMENT)));
    await assertFails(getDoc(doc(await asUser(OLIVIA), ENTITLEMENT)));
    await assertFails(getDoc(doc(await asSignedOut(), ENTITLEMENT)));
  });

  it('cannot be created by the admin, however it is dressed', async () => {
    await clearData();
    await givenTheParkers();
    await assertFails(setDoc(doc(await asUser(SAM), ENTITLEMENT), premiumFor(365)));
  });

  it('cannot be extended, shortened or deleted by anybody in the household', async () => {
    for (const uid of [SAM, MIA, THANDI]) {
      const db = await asUser(uid);
      await assertFails(updateDoc(doc(db, ENTITLEMENT), premiumFor(3650)));
      await assertFails(updateDoc(doc(db, ENTITLEMENT), { premiumUntil: null }));
      await assertFails(deleteDoc(doc(db, ENTITLEMENT)));
    }
  });
});

describe('storePurchases', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
    await givenPremium();
  });

  it('is read by nobody — not even the admin of the household it gives premium to', async () => {
    await assertFails(getDoc(doc(await asUser(SAM), PURCHASE)));
    await assertFails(getDoc(doc(await asSignedOut(), PURCHASE)));
  });

  it('is written by nobody, so no purchase can be claimed or moved from a phone', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), 'storePurchases/new'), { householdId: HOUSEHOLD }),
    );
    await assertFails(updateDoc(doc(await asUser(SAM), PURCHASE), { householdId: 'h2' }));
    await assertFails(deleteDoc(doc(await asUser(SAM), PURCHASE)));
  });
});

describe('who is a child, which the free tier counts', () => {
  beforeEach(async () => {
    await clearData();
    await givenTheParkers();
    await givenTheKidsDetails();
  });

  it('cannot be set by the admin creating a profile — premium or not', async () => {
    await givenPremium();
    await assertFails(
      setDoc(doc(await asUser(SAM), `${PROFILES}/m-mia`), { isChild: true }, merge),
    );
  });

  it('cannot be switched on over an existing profile', async () => {
    await givenData(async (db) => {
      await setDoc(doc(db, `${PROFILES}/${THANDI_MEMBER}`), { isChild: false, likes: ['Tea'] });
    });
    await assertFails(
      setDoc(doc(await asUser(SAM), `${PROFILES}/${THANDI_MEMBER}`), { isChild: true }, merge),
    );
    // Not even by the person themselves, who may otherwise edit their own.
    await assertFails(
      setDoc(doc(await asUser(THANDI), `${PROFILES}/${THANDI_MEMBER}`), { isChild: true }, merge),
    );
  });

  it('cannot be switched off from a phone either — it is one callable both ways', async () => {
    await assertFails(
      setDoc(doc(await asUser(SAM), `${PROFILES}/${KID}`), { isChild: false }, merge),
    );
  });

  it('leaves every other edit of a child’s profile to the admin as before', async () => {
    await assertSucceeds(
      setDoc(doc(await asUser(SAM), `${PROFILES}/${KID}`), { likes: ['Pasta', 'Pears'] }, merge),
    );
    // A write that repeats the flag unchanged is not a change to it.
    await assertSucceeds(
      setDoc(
        doc(await asUser(SAM), `${PROFILES}/${KID}`),
        { isChild: true, grade: 'Grade 4' },
        merge,
      ),
    );
  });

  it('lets an admin create a grown-up’s profile that says, plainly, not a child', async () => {
    await assertSucceeds(
      setDoc(
        doc(await asUser(SAM), `${PROFILES}/m-mia`),
        { isChild: false, likes: ['Coffee'] },
        merge,
      ),
    );
  });
});
