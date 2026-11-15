import { Timestamp, doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import { HOME, HOUSEHOLD, KID_DEVICE, PEOPLE, givenAHouseholdOfEveryRole } from './access_fixture';
import {
  asKid,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * Where avatars' free tier ends (subscriptions ADR-0008): a free household
 * picks a Nestling, the initial or a photo, keeps what it already wears and
 * may take it off; putting anything on, the star shop, made pictures and
 * wearing a keepsake are Premium. Deleting a keepsake is never gated.
 */

const HASH = '0123456789abcdef0123456789abcdef';
const OTHER_HASH = 'fedcba9876543210fedcba9876543210';
const KID = PEOPLE.kid.member;
const SAM = PEOPLE.admin.member;
const DAY = 24 * 60 * 60 * 1000;

const admin = (): Promise<Firestore> => asUser(PEOPLE.admin.uid);
const kidDevice = (): Promise<Firestore> =>
  asKid(KID_DEVICE, { householdId: HOUSEHOLD, memberId: KID });

const avatarOf = (memberId: string): string => `${HOME}/memberAvatars/${memberId}`;

function choice(by: string, base: string, wear: Record<string, string>): Record<string, unknown> {
  return { choice: { base, wear }, updatedBy: by, updatedAt: serverTimestamp() };
}

const purchase = (): Record<string, unknown> => ({
  memberId: KID,
  accessoryId: 'acc-crown',
  requestedBy: KID,
  requestedAt: serverTimestamp(),
});

const creation = (): Record<string, unknown> => ({
  memberId: KID,
  recipe: 'buddy',
  buddy: { creature: 'dragon', colour: 'pink', loves: 'pancakes', wears: 'cape', power: 'flying' },
  requestedBy: KID,
  requestedAt: serverTimestamp(),
});

const portrait = (): Record<string, unknown> => ({
  memberId: SAM,
  recipe: 'portrait',
  requestedBy: SAM,
  requestedAt: serverTimestamp(),
});

const keepsakeDelete = (): Record<string, unknown> => ({
  requestedBy: KID,
  requestedAt: serverTimestamp(),
});

/** No avatar document: what the kid wears is only on the look the Functions mirrored. */
async function givenOnlyAMirroredLook(): Promise<void> {
  await givenData(async (db) => {
    await updateDoc(doc(db, `${HOME}/members/${KID}`), {
      look: { v: 1, base: 'preset:pip', stage: 1, wear: { badge: 'acc-star' } },
    });
  });
}

async function givenPremium(millisFromNow: number): Promise<void> {
  await givenData(async (db) => {
    await setDoc(doc(db, `${HOME}/entitlement/current`), {
      premiumUntil: Timestamp.fromMillis(Date.now() + millisFromNow),
    });
  });
}

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await givenData(async (db) => {
    await setDoc(doc(db, avatarOf(SAM)), {
      choice: { base: 'preset:pip', wear: { top: 'acc-crown' } },
      owned: { accessories: ['acc-crown'], images: [HASH] },
      updatedBy: SAM,
      updatedAt: new Date(),
    });
    await setDoc(doc(db, `${HOME}/avatarKeepsakes/kept`), {
      memberId: KID,
      recipe: 'drawing',
      style: 'plush',
      originalPath: null,
      imageHash: HASH,
      createdAt: new Date(),
      createdBy: KID,
    });
  });
});

describe('a free household', () => {
  it('picks a Nestling or the initial for somebody with no look yet', async () => {
    await assertSucceeds(
      setDoc(doc(await kidDevice(), avatarOf(KID)), choice(KID, 'preset:pip', {})),
    );
    await assertSucceeds(
      setDoc(doc(await admin(), avatarOf(PEOPLE.parent.member)), choice(SAM, 'initial', {})),
    );
  });

  it('changes the Nestling, the stage and the photo with what is worn carried over', async () => {
    const db = await admin();
    await assertSucceeds(
      setDoc(doc(db, avatarOf(SAM)), choice(SAM, 'preset:bo', { top: 'acc-crown' }), {
        mergeFields: ['choice', 'updatedBy', 'updatedAt'],
      }),
    );
    await assertSucceeds(
      updateDoc(doc(db, avatarOf(SAM)), {
        choice: { base: 'initial', stage: 2, wear: { top: 'acc-crown' } },
        updatedBy: SAM,
        updatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      setDoc(
        doc(db, avatarOf(SAM)),
        { ...choice(SAM, 'initial', { top: 'acc-crown' }), pendingPhoto: OTHER_HASH },
        { mergeFields: ['choice', 'pendingPhoto', 'updatedBy', 'updatedAt'] },
      ),
    );
  });

  it('puts nothing on and swaps nothing', async () => {
    const db = await admin();
    for (const wear of [
      { top: 'acc-star-crown' },
      { top: 'acc-crown', badge: 'acc-star' },
      { badge: 'acc-star' },
    ]) {
      await assertFails(updateDoc(doc(db, avatarOf(SAM)), choice(SAM, 'preset:pip', wear)));
    }
    await assertFails(
      setDoc(
        doc(await kidDevice(), avatarOf(KID)),
        choice(KID, 'preset:pip', { top: 'acc-crown' }),
      ),
    );
  });

  it('takes off what is worn, and does not put it back on', async () => {
    const db = await admin();
    await assertSucceeds(updateDoc(doc(db, avatarOf(SAM)), choice(SAM, 'preset:pip', {})));
    await assertFails(
      updateDoc(doc(db, avatarOf(SAM)), choice(SAM, 'preset:pip', { top: 'acc-crown' })),
    );
  });

  it('moves from a Nestling to the initial without the glasses the initial cannot wear', async () => {
    await givenData(async (db) => {
      await updateDoc(doc(db, avatarOf(SAM)), {
        'choice.wear': { top: 'acc-crown', face: 'acc-round-glasses' },
      });
    });
    const db = await admin();
    await assertSucceeds(
      updateDoc(doc(db, avatarOf(SAM)), choice(SAM, 'initial', { top: 'acc-crown' })),
    );
    await assertFails(
      updateDoc(
        doc(db, avatarOf(SAM)),
        choice(SAM, 'preset:pip', { top: 'acc-crown', face: 'acc-round-glasses' }),
      ),
    );
  });

  it('creates a first choice that carries over what the mirrored look wears', async () => {
    await givenOnlyAMirroredLook();
    const db = await kidDevice();
    for (const wear of [
      { badge: 'acc-book' },
      { badge: 'acc-star', top: 'acc-party-hat' },
      { top: 'acc-party-hat' },
    ]) {
      await assertFails(setDoc(doc(db, avatarOf(KID)), choice(KID, 'preset:pip', wear)));
    }
    await assertFails(
      setDoc(doc(db, avatarOf(KID)), choice(KID, `image:${HASH}`, { badge: 'acc-star' })),
    );
    await assertSucceeds(
      setDoc(doc(db, avatarOf(KID)), choice(KID, 'preset:bo', { badge: 'acc-star' })),
    );
  });

  it('creates a first choice that takes off what the mirrored look wears', async () => {
    await givenOnlyAMirroredLook();
    await assertSucceeds(setDoc(doc(await kidDevice(), avatarOf(KID)), choice(KID, 'initial', {})));
  });

  it('carries over what the mirrored look wears when the stored document has no choice', async () => {
    await givenData(async (db) => {
      await updateDoc(doc(db, `${HOME}/members/${KID}`), {
        look: { v: 1, base: `image:${HASH}`, stage: 1, wear: { badge: 'acc-star' } },
      });
      await setDoc(doc(db, avatarOf(KID)), {
        owned: { accessories: ['acc-star'], images: [HASH] },
      });
    });
    const db = await kidDevice();
    const merge = { mergeFields: ['choice', 'updatedBy', 'updatedAt'] };
    await assertFails(
      setDoc(doc(db, avatarOf(KID)), choice(KID, 'preset:pip', { badge: 'acc-book' }), merge),
    );
    await assertSucceeds(
      setDoc(doc(db, avatarOf(KID)), choice(KID, `image:${HASH}`, { badge: 'acc-star' }), merge),
    );
    await assertSucceeds(
      setDoc(doc(db, avatarOf(KID)), choice(KID, 'preset:pip', { badge: 'acc-star' }), merge),
    );
  });

  it('keeps a made picture it wears, and puts on no other', async () => {
    await givenData(async (db) => {
      await updateDoc(doc(db, avatarOf(SAM)), { 'choice.base': `image:${HASH}` });
    });
    const db = await admin();
    await assertSucceeds(
      updateDoc(doc(db, avatarOf(SAM)), {
        choice: { base: `image:${HASH}`, stage: 1, wear: { top: 'acc-crown' } },
        updatedBy: SAM,
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(
      updateDoc(doc(db, avatarOf(SAM)), choice(SAM, `image:${OTHER_HASH}`, { top: 'acc-crown' })),
    );
    await assertSucceeds(
      updateDoc(doc(db, avatarOf(SAM)), choice(SAM, 'preset:pip', { top: 'acc-crown' })),
    );
    await assertFails(
      updateDoc(doc(db, avatarOf(SAM)), choice(SAM, `image:${HASH}`, { top: 'acc-crown' })),
    );
    await assertFails(
      setDoc(doc(await kidDevice(), avatarOf(KID)), choice(KID, `image:${HASH}`, {})),
    );
  });

  it('buys nothing in the star shop and asks for no picture', async () => {
    await assertFails(setDoc(doc(await kidDevice(), `${HOME}/avatarPurchases/p1`), purchase()));
    await assertFails(
      setDoc(doc(await admin(), `${HOME}/avatarPurchases/p2`), { ...purchase(), requestedBy: SAM }),
    );
    await assertFails(setDoc(doc(await kidDevice(), `${HOME}/avatarCreations/c1`), creation()));
    await assertFails(setDoc(doc(await admin(), `${HOME}/avatarCreations/c2`), portrait()));
  });

  it('still deletes a keepsake', async () => {
    await assertSucceeds(
      setDoc(doc(await kidDevice(), `${HOME}/avatarKeepsakeDeletes/kept`), keepsakeDelete()),
    );
  });
});

describe('a household whose Premium has lapsed', () => {
  beforeEach(() => givenPremium(-60_000));

  it('is free again', async () => {
    await assertFails(
      updateDoc(doc(await admin(), avatarOf(SAM)), choice(SAM, 'preset:pip', { top: 'acc-cap' })),
    );
    await assertSucceeds(
      updateDoc(doc(await admin(), avatarOf(SAM)), choice(SAM, 'preset:bo', { top: 'acc-crown' })),
    );
    await assertSucceeds(updateDoc(doc(await admin(), avatarOf(SAM)), choice(SAM, 'initial', {})));
    await assertFails(
      updateDoc(doc(await admin(), avatarOf(SAM)), choice(SAM, 'initial', { top: 'acc-crown' })),
    );
    await assertFails(setDoc(doc(await kidDevice(), `${HOME}/avatarPurchases/p1`), purchase()));
    await assertFails(setDoc(doc(await kidDevice(), `${HOME}/avatarCreations/c1`), creation()));
  });
});

describe('a household with Premium', () => {
  beforeEach(() => givenPremium(DAY));

  it('changes what is worn, on a new look and a stored one', async () => {
    await assertSucceeds(
      setDoc(
        doc(await kidDevice(), avatarOf(KID)),
        choice(KID, 'preset:pip', { top: 'acc-crown' }),
      ),
    );
    for (const wear of [{}, { top: 'acc-star-crown' }, { top: 'acc-crown', badge: 'acc-star' }]) {
      await assertSucceeds(
        updateDoc(doc(await admin(), avatarOf(SAM)), choice(SAM, 'preset:pip', wear)),
      );
    }
  });

  it('creates a first choice that changes what the mirrored look wears', async () => {
    await givenOnlyAMirroredLook();
    await assertSucceeds(
      setDoc(
        doc(await kidDevice(), avatarOf(KID)),
        choice(KID, 'preset:pip', { badge: 'acc-book', top: 'acc-party-hat' }),
      ),
    );
  });

  it('wears a made picture', async () => {
    await assertSucceeds(
      updateDoc(doc(await admin(), avatarOf(SAM)), choice(SAM, `image:${HASH}`, {})),
    );
  });

  it('buys in the star shop and asks for a picture', async () => {
    await assertSucceeds(setDoc(doc(await kidDevice(), `${HOME}/avatarPurchases/p1`), purchase()));
    await assertSucceeds(setDoc(doc(await kidDevice(), `${HOME}/avatarCreations/c1`), creation()));
    await assertSucceeds(
      setDoc(doc(await admin(), `${HOME}/avatarPurchases/p2`), { ...purchase(), requestedBy: SAM }),
    );
    await assertSucceeds(setDoc(doc(await admin(), `${HOME}/avatarCreations/c2`), portrait()));
  });

  it('deletes a keepsake', async () => {
    await assertSucceeds(
      setDoc(doc(await kidDevice(), `${HOME}/avatarKeepsakeDeletes/kept`), keepsakeDelete()),
    );
  });
});
