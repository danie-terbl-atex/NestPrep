import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { beforeEach, describe, it } from 'vitest';

import {
  HOME,
  HOUSEHOLD,
  KID_DEVICE,
  PEOPLE,
  givenAHouseholdOfEveryRole,
  type Person,
} from './access_fixture';
import {
  asKid,
  asSignedOut,
  asUser,
  assertFails,
  assertSucceeds,
  clearData,
  givenData,
  type Firestore,
} from './rules_harness';

/**
 * Avatars (avatars ADR-0001 to ADR-0006): everyone in the household reads a
 * look, kid devices included; family writes anyone's choice and a member
 * their own; what is owned, the mirrored look and every outcome are the
 * Functions' alone.
 */

const HASH = '0123456789abcdef0123456789abcdef';
const KID = PEOPLE.kid.member;
const SAM = PEOPLE.admin.member;
const CLEANER = PEOPLE.cleaner.member;

const as = (person: Person): Promise<Firestore> => asUser(PEOPLE[person].uid);
const kidDevice = (): Promise<Firestore> =>
  asKid(KID_DEVICE, { householdId: HOUSEHOLD, memberId: KID });

function choiceBy(by: string, overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    choice: { base: 'preset:pip', wear: { top: 'acc-crown' } },
    updatedBy: by,
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

const avatarOf = (memberId: string): string => `${HOME}/memberAvatars/${memberId}`;

beforeEach(async () => {
  await clearData();
  await givenAHouseholdOfEveryRole();
  await givenData(async (db) => {
    await setDoc(doc(db, `${HOME}/entitlement/current`), {
      premiumUntil: Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000),
    });
    await setDoc(doc(db, avatarOf(SAM)), {
      choice: { base: 'initial', wear: {} },
      owned: { accessories: ['acc-crown'], images: [HASH] },
      updatedBy: SAM,
      updatedAt: new Date(),
    });
    await setDoc(doc(db, `${HOME}/avatarPurchases/bought`), {
      memberId: KID,
      accessoryId: 'acc-crown',
      requestedBy: KID,
      requestedAt: new Date(),
      status: 'owned',
    });
    await setDoc(doc(db, `${HOME}/avatarCreations/made`), {
      memberId: KID,
      recipe: 'drawing',
      requestedBy: KID,
      requestedAt: new Date(),
      status: 'ready',
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
    await setDoc(doc(db, `${HOME}/avatarKeepsakes/samKept`), {
      memberId: SAM,
      recipe: 'buddy',
      style: 'clay',
      originalPath: null,
      imageHash: HASH,
      createdAt: new Date(),
      createdBy: SAM,
    });
  });
});

describe('memberAvatars — reading a look', () => {
  it('lets everyone in the household read it, a kid device too', async () => {
    for (const person of Object.keys(PEOPLE) as Person[]) {
      await assertSucceeds(getDoc(doc(await as(person), avatarOf(SAM))));
    }
    await assertSucceeds(getDoc(doc(await kidDevice(), avatarOf(SAM))));
  });

  it('denies a stranger, another household and nobody at all', async () => {
    await assertFails(getDoc(doc(await asUser('uid-stranger'), avatarOf(SAM))));
    await assertFails(getDoc(doc(await asSignedOut(), avatarOf(SAM))));
    await assertFails(
      getDoc(
        doc(await asKid('kid_other', { householdId: 'h-other', memberId: KID }), avatarOf(SAM)),
      ),
    );
  });
});

describe('memberAvatars — choosing a look', () => {
  it('lets family choose for anyone, and a member for themselves', async () => {
    await assertSucceeds(setDoc(doc(await as('admin'), avatarOf(KID)), choiceBy(SAM)));
    await assertSucceeds(
      setDoc(doc(await as('parent'), avatarOf(CLEANER)), choiceBy(PEOPLE.parent.member)),
    );
    await assertSucceeds(setDoc(doc(await as('cleaner'), avatarOf(CLEANER)), choiceBy(CLEANER)));
  });

  it('lets a kid device choose its own child’s look, and nobody else’s', async () => {
    await assertSucceeds(setDoc(doc(await kidDevice(), avatarOf(KID)), choiceBy(KID)));
    await assertFails(setDoc(doc(await kidDevice(), avatarOf(CLEANER)), choiceBy(KID)));
  });

  it('denies a helper or a kid choosing somebody else’s', async () => {
    await assertFails(setDoc(doc(await as('cleaner'), avatarOf(KID)), choiceBy(CLEANER)));
    await assertFails(setDoc(doc(await as('kid'), avatarOf(CLEANER)), choiceBy(KID)));
    await assertFails(
      setDoc(doc(await as('viewer'), avatarOf(KID)), choiceBy(PEOPLE.viewer.member)),
    );
  });

  it('denies a stranger, and a look for somebody who is not a member', async () => {
    await assertFails(setDoc(doc(await asUser('uid-stranger'), avatarOf(KID)), choiceBy(KID)));
    await assertFails(setDoc(doc(await as('admin'), avatarOf('m-nobody')), choiceBy(SAM)));
  });

  it('denies a choice signed as somebody else, or at a time of the client’s choosing', async () => {
    await assertFails(setDoc(doc(await as('cleaner'), avatarOf(CLEANER)), choiceBy(SAM)));
    await assertFails(
      setDoc(doc(await as('admin'), avatarOf(KID)), choiceBy(SAM, { updatedAt: new Date() })),
    );
    const unsigned = choiceBy(SAM);
    delete unsigned['updatedBy'];
    await assertFails(setDoc(doc(await as('admin'), avatarOf(KID)), unsigned));
  });

  it('takes a base of the three kinds, and a stage of 0 to 3', async () => {
    const db = await as('admin');
    for (const base of ['initial', 'preset:pip', `image:${HASH}`]) {
      await assertSucceeds(
        setDoc(doc(db, avatarOf(KID)), choiceBy(SAM, { choice: { base, stage: 3, wear: {} } })),
      );
    }
    for (const base of ['', 'Pip', 'preset:Pip!', 'image:abc', `image:${HASH}0`, 'emoji:cat', 7]) {
      await assertFails(
        setDoc(doc(db, avatarOf(KID)), choiceBy(SAM, { choice: { base, wear: {} } })),
      );
    }
    for (const stage of [-1, 4, 1.5, '2']) {
      await assertFails(
        setDoc(
          doc(db, avatarOf(KID)),
          choiceBy(SAM, { choice: { base: 'initial', stage, wear: {} } }),
        ),
      );
    }
  });

  it('wears accessory ids in the four slots, and nothing else', async () => {
    const db = await as('admin');
    await assertSucceeds(
      setDoc(
        doc(db, avatarOf(KID)),
        choiceBy(SAM, {
          choice: {
            base: 'preset:pip',
            wear: {
              top: 'acc-crown',
              badge: 'acc-star',
              ring: 'acc-gold-ring',
              face: 'acc-monocle',
            },
          },
        }),
      ),
    );
    for (const wear of [
      { hat: 'acc-crown' },
      { top: 'crown' },
      { top: 'moment-birthday-hat' },
      { top: 'acc-CROWN' },
      { top: 3 },
      { top: `acc-${'a'.repeat(45)}` },
      'acc-crown',
    ]) {
      await assertFails(
        setDoc(doc(db, avatarOf(KID)), choiceBy(SAM, { choice: { base: 'initial', wear } })),
      );
    }
    for (const choice of [
      { base: 'initial' },
      { wear: {} },
      { base: 'initial', wear: {}, colour: 'red' },
      'preset:pip',
    ]) {
      await assertFails(setDoc(doc(db, avatarOf(KID)), choiceBy(SAM, { choice })));
    }
  });

  it('takes a waiting photo only as a hash', async () => {
    const db = await as('admin');
    await assertSucceeds(setDoc(doc(db, avatarOf(KID)), choiceBy(SAM, { pendingPhoto: HASH })));
    for (const pendingPhoto of ['abc', HASH.toUpperCase(), `../${HASH}`, 12]) {
      await assertFails(setDoc(doc(db, avatarOf(KID)), choiceBy(SAM, { pendingPhoto })));
    }
  });

  it('never lets a client say what is owned, or add a key of its own', async () => {
    await assertFails(
      setDoc(
        doc(await kidDevice(), avatarOf(KID)),
        choiceBy(KID, { owned: { accessories: ['acc-star-crown'], images: [] } }),
      ),
    );
    await assertFails(setDoc(doc(await as('admin'), avatarOf(KID)), choiceBy(SAM, { look: {} })));
  });
});

describe('memberAvatars — changing a look', () => {
  it('lets the member change their choice and leave what they own alone', async () => {
    await assertSucceeds(
      updateDoc(doc(await as('admin'), avatarOf(SAM)), {
        choice: { base: `image:${HASH}`, wear: {} },
        updatedBy: SAM,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('denies any change to what is owned, by anybody', async () => {
    for (const owned of [
      { accessories: ['acc-crown', 'acc-star-crown'], images: [HASH] },
      { accessories: [], images: [] },
    ]) {
      await assertFails(
        updateDoc(doc(await as('admin'), avatarOf(SAM)), {
          owned,
          updatedBy: SAM,
          updatedAt: serverTimestamp(),
        }),
      );
    }
  });

  it('takes a new photo merged in, and denies a whole document that drops what is owned', async () => {
    const offer = choiceBy(SAM, { pendingPhoto: HASH });
    await assertFails(setDoc(doc(await as('admin'), avatarOf(SAM)), offer));
    await assertSucceeds(setDoc(doc(await as('admin'), avatarOf(SAM)), offer, { merge: true }));
  });

  it('denies a helper changing family’s look, and anybody deleting one', async () => {
    await assertFails(
      updateDoc(doc(await as('cleaner'), avatarOf(SAM)), {
        choice: { base: 'initial', wear: {} },
        updatedBy: CLEANER,
        updatedAt: serverTimestamp(),
      }),
    );
    await assertFails(deleteDoc(doc(await as('admin'), avatarOf(SAM))));
  });
});

function purchaseBy(by: string, overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    memberId: KID,
    accessoryId: 'acc-crown',
    requestedBy: by,
    requestedAt: serverTimestamp(),
    ...overrides,
  };
}

describe('avatarPurchases — buying in the Wardrobe', () => {
  it('lets a child buy for themselves, on their own device too, and family for them', async () => {
    await assertSucceeds(
      setDoc(doc(await kidDevice(), `${HOME}/avatarPurchases/p1`), purchaseBy(KID)),
    );
    await assertSucceeds(
      setDoc(doc(await as('kid'), `${HOME}/avatarPurchases/p2`), purchaseBy(KID)),
    );
    await assertSucceeds(
      setDoc(
        doc(await as('parent'), `${HOME}/avatarPurchases/p3`),
        purchaseBy(PEOPLE.parent.member),
      ),
    );
  });

  it('denies buying for somebody else, or in somebody else’s name', async () => {
    await assertFails(
      setDoc(
        doc(await kidDevice(), `${HOME}/avatarPurchases/p1`),
        purchaseBy(KID, { memberId: SAM }),
      ),
    );
    await assertFails(
      setDoc(doc(await as('cleaner'), `${HOME}/avatarPurchases/p1`), purchaseBy(CLEANER)),
    );
    await assertFails(
      setDoc(doc(await kidDevice(), `${HOME}/avatarPurchases/p1`), purchaseBy(SAM)),
    );
    await assertFails(
      setDoc(doc(await asUser('uid-stranger'), `${HOME}/avatarPurchases/p1`), purchaseBy(KID)),
    );
  });

  it('takes exactly four fields, and never the outcome', async () => {
    const db = await kidDevice();
    const path = `${HOME}/avatarPurchases/p1`;
    for (const overrides of [
      { status: 'owned' },
      { reason: null },
      { stars: 0 },
      { accessoryId: 'crown' },
      { accessoryId: 'acc-Crown' },
      { memberId: 'm-nobody' },
      { requestedAt: new Date() },
    ]) {
      await assertFails(setDoc(doc(db, path), purchaseBy(KID, overrides)));
    }
    const undated = purchaseBy(KID);
    delete undated['requestedAt'];
    await assertFails(setDoc(doc(db, path), undated));
  });

  it('is read by the household, and never changed or taken back by a client', async () => {
    await assertSucceeds(getDoc(doc(await kidDevice(), `${HOME}/avatarPurchases/bought`)));
    await assertFails(getDoc(doc(await asUser('uid-stranger'), `${HOME}/avatarPurchases/bought`)));
    await assertFails(
      updateDoc(doc(await as('admin'), `${HOME}/avatarPurchases/bought`), { status: 'refused' }),
    );
    await assertFails(deleteDoc(doc(await as('admin'), `${HOME}/avatarPurchases/bought`)));
  });
});

const BUDDY = {
  creature: 'dragon',
  colour: 'pink',
  loves: 'pancakes',
  wears: 'cape',
  power: 'flying',
};

function creationBy(by: string, overrides: Record<string, unknown> = {}): Record<string, unknown> {
  const creation: Record<string, unknown> = {
    memberId: KID,
    recipe: 'buddy',
    buddy: BUDDY,
    requestedBy: by,
    requestedAt: serverTimestamp(),
    ...overrides,
  };
  return Object.fromEntries(Object.entries(creation).filter(([, value]) => value !== undefined));
}

const drawingBy = (by: string, overrides: Record<string, unknown> = {}): Record<string, unknown> =>
  creationBy(by, { recipe: 'drawing', buddy: undefined, inboxId: 'photo-1234', ...overrides });

describe('avatarCreations — asking for a picture to be made', () => {
  it('lets a child ask for themselves and family for anyone, with the recipe’s choices', async () => {
    await assertSucceeds(
      setDoc(
        doc(await kidDevice(), `${HOME}/avatarCreations/c1`),
        creationBy(KID, { style: 'plush', buddy: BUDDY, extra: 'with a tiny umbrella' }),
      ),
    );
    await assertSucceeds(
      setDoc(
        doc(await as('admin'), `${HOME}/avatarCreations/c2`),
        drawingBy(SAM, { style: 'clay' }),
      ),
    );
    await assertSucceeds(
      setDoc(
        doc(await kidDevice(), `${HOME}/avatarCreations/c4`),
        drawingBy(KID, { recipe: 'pet', style: 'vinyl' }),
      ),
    );
    await assertSucceeds(
      setDoc(
        doc(await as('admin'), `${HOME}/avatarCreations/c3`),
        creationBy(SAM, { recipe: 'portrait', memberId: SAM, buddy: undefined }),
      ),
    );
  });

  it('holds each recipe to its own ingredients', async () => {
    const db = await as('admin');
    const path = `${HOME}/avatarCreations/c5`;
    for (const shaped of [
      drawingBy(SAM, { inboxId: undefined }),
      drawingBy(SAM, { recipe: 'pet', inboxId: undefined }),
      drawingBy(SAM, { buddy: BUDDY }),
      drawingBy(SAM, { extra: 'with a hat' }),
      creationBy(SAM, { buddy: undefined }),
      creationBy(SAM, { inboxId: 'photo-1234' }),
      creationBy(SAM, { recipe: 'portrait', memberId: SAM, buddy: undefined, style: 'clay' }),
      creationBy(SAM, { recipe: 'portrait', memberId: SAM }),
      creationBy(SAM, {
        recipe: 'portrait',
        memberId: SAM,
        buddy: undefined,
        inboxId: 'photo-1234',
      }),
      creationBy(SAM, { recipe: 'portrait', buddy: undefined }),
    ]) {
      await assertFails(setDoc(doc(db, path), shaped));
    }
  });

  it('leaves the portrait to family', async () => {
    const portrait = (member: string): Record<string, unknown> =>
      creationBy(member, { recipe: 'portrait', memberId: member, buddy: undefined });
    await assertFails(setDoc(doc(await kidDevice(), `${HOME}/avatarCreations/p1`), portrait(KID)));
    await assertFails(setDoc(doc(await as('kid'), `${HOME}/avatarCreations/p1`), portrait(KID)));
    await assertFails(
      setDoc(doc(await as('cleaner'), `${HOME}/avatarCreations/p1`), portrait(CLEANER)),
    );
    await assertSucceeds(
      setDoc(doc(await as('parent'), `${HOME}/avatarCreations/p1`), portrait(PEOPLE.parent.member)),
    );
  });

  it('denies asking for somebody else, or in somebody else’s name', async () => {
    await assertFails(
      setDoc(doc(await as('cleaner'), `${HOME}/avatarCreations/c1`), creationBy(CLEANER)),
    );
    await assertFails(
      setDoc(doc(await kidDevice(), `${HOME}/avatarCreations/c1`), creationBy(SAM)),
    );
    await assertFails(
      setDoc(doc(await asSignedOut(), `${HOME}/avatarCreations/c1`), creationBy(KID)),
    );
  });

  it('takes only the recipe’s own shapes, and never the outcome', async () => {
    const db = await kidDevice();
    const path = `${HOME}/avatarCreations/c1`;
    for (const overrides of [
      { recipe: 'selfie' },
      { style: 'oil' },
      { buddy: { ...BUDDY, power: undefined } },
      { buddy: { ...BUDDY, pet: 'cat' } },
      { buddy: { ...BUDDY, creature: 'Dragon!' } },
      { extra: 'x'.repeat(61) },
      { extra: 7 },
      { inboxId: 'short' },
      { inboxId: '../photo-1234' },
      { status: 'ready' },
      { imageHash: HASH },
      { left: 12 },
      { requestedAt: new Date() },
    ]) {
      const shaped = Object.fromEntries(
        Object.entries(creationBy(KID, overrides)).map(([key, value]) => [
          key,
          key === 'buddy' && typeof value === 'object' && value !== null
            ? Object.fromEntries(Object.entries(value).filter(([, part]) => part !== undefined))
            : value,
        ]),
      );
      await assertFails(setDoc(doc(db, path), shaped));
    }
  });

  it('is read by the household, and never changed or taken back by a client', async () => {
    await assertSucceeds(getDoc(doc(await kidDevice(), `${HOME}/avatarCreations/made`)));
    await assertFails(getDoc(doc(await asUser('uid-stranger'), `${HOME}/avatarCreations/made`)));
    await assertFails(
      updateDoc(doc(await as('admin'), `${HOME}/avatarCreations/made`), { status: 'checking' }),
    );
    await assertFails(deleteDoc(doc(await as('admin'), `${HOME}/avatarCreations/made`)));
  });
});

describe('avatarKeepsakes — what a creation was made from', () => {
  it('is read by the household, kid devices too', async () => {
    await assertSucceeds(getDoc(doc(await as('admin'), `${HOME}/avatarKeepsakes/kept`)));
    await assertSucceeds(getDoc(doc(await kidDevice(), `${HOME}/avatarKeepsakes/kept`)));
    await assertFails(getDoc(doc(await asUser('uid-stranger'), `${HOME}/avatarKeepsakes/kept`)));
  });

  it('is written by Functions alone', async () => {
    await assertFails(
      setDoc(doc(await as('admin'), `${HOME}/avatarKeepsakes/new`), {
        memberId: KID,
        recipe: 'drawing',
        style: 'plush',
        originalPath: null,
        imageHash: HASH,
        createdAt: serverTimestamp(),
        createdBy: SAM,
      }),
    );
    await assertFails(deleteDoc(doc(await as('admin'), `${HOME}/avatarKeepsakes/kept`)));
    await assertFails(
      updateDoc(doc(await kidDevice(), `${HOME}/avatarKeepsakes/kept`), { style: 'clay' }),
    );
  });
});

describe('avatarKeepsakeDeletes — taking a keepsake off the shelf', () => {
  const askBy = (by: string, overrides: Record<string, unknown> = {}): Record<string, unknown> => ({
    requestedBy: by,
    requestedAt: serverTimestamp(),
    ...overrides,
  });

  it('lets the member it belongs to ask, a kid device too', async () => {
    await assertSucceeds(
      setDoc(doc(await kidDevice(), `${HOME}/avatarKeepsakeDeletes/kept`), askBy(KID)),
    );
    await assertSucceeds(
      setDoc(doc(await as('admin'), `${HOME}/avatarKeepsakeDeletes/samKept`), askBy(SAM)),
    );
  });

  it('lets family ask for anyone’s', async () => {
    await assertSucceeds(
      setDoc(
        doc(await as('parent'), `${HOME}/avatarKeepsakeDeletes/kept`),
        askBy(PEOPLE.parent.member),
      ),
    );
  });

  it('denies somebody else’s keepsake, one that does not exist, and a stranger', async () => {
    await assertFails(
      setDoc(doc(await kidDevice(), `${HOME}/avatarKeepsakeDeletes/samKept`), askBy(KID)),
    );
    await assertFails(
      setDoc(doc(await as('cleaner'), `${HOME}/avatarKeepsakeDeletes/kept`), askBy(CLEANER)),
    );
    await assertFails(
      setDoc(doc(await as('admin'), `${HOME}/avatarKeepsakeDeletes/nothing`), askBy(SAM)),
    );
    await assertFails(
      setDoc(doc(await asUser('uid-stranger'), `${HOME}/avatarKeepsakeDeletes/kept`), askBy(KID)),
    );
    await assertFails(
      setDoc(doc(await asSignedOut(), `${HOME}/avatarKeepsakeDeletes/kept`), askBy(KID)),
    );
  });

  it('takes the two stamps and nothing else, at the server’s time and in the caller’s own name', async () => {
    const db = await kidDevice();
    const path = `${HOME}/avatarKeepsakeDeletes/kept`;
    await assertFails(setDoc(doc(db, path), askBy(SAM)));
    await assertFails(setDoc(doc(db, path), askBy(KID, { requestedAt: new Date() })));
    await assertFails(setDoc(doc(db, path), askBy(KID, { imageHash: HASH })));
    await assertFails(setDoc(doc(db, path), { requestedBy: KID }));
  });

  it('is read by the household, and never changed or taken back by a client', async () => {
    await givenData(async (admin) => {
      await setDoc(doc(admin, `${HOME}/avatarKeepsakeDeletes/kept`), {
        requestedBy: KID,
        requestedAt: new Date(),
      });
    });
    await assertSucceeds(getDoc(doc(await kidDevice(), `${HOME}/avatarKeepsakeDeletes/kept`)));
    await assertFails(
      getDoc(doc(await asUser('uid-stranger'), `${HOME}/avatarKeepsakeDeletes/kept`)),
    );
    await assertFails(
      updateDoc(doc(await as('admin'), `${HOME}/avatarKeepsakeDeletes/kept`), { requestedBy: SAM }),
    );
    await assertFails(deleteDoc(doc(await as('admin'), `${HOME}/avatarKeepsakeDeletes/kept`)));
  });
});

describe('a member’s look on their profile', () => {
  const LOOK = { v: 1, base: 'preset:pip', stage: 2, wear: {} };

  beforeEach(async () => {
    await givenData(async (db) => {
      await updateDoc(doc(db, `${HOME}/members/${KID}`), { look: LOOK });
    });
  });

  it('is never written by a client, an admin included', async () => {
    const db = await as('admin');
    await assertFails(
      updateDoc(doc(db, `${HOME}/members/${KID}`), { look: { ...LOOK, stage: 3 } }),
    );
    await assertFails(updateDoc(doc(db, `${HOME}/members/${SAM}`), { look: LOOK }));
    await assertFails(
      setDoc(doc(db, `${HOME}/members/m-new`), {
        displayName: 'Gogo',
        color: 'mint',
        role: 'helper',
        claimedBy: null,
        createdAt: serverTimestamp(),
        look: LOOK,
      }),
    );
  });

  it('stays as it is while an admin edits the rest of the profile', async () => {
    await assertSucceeds(
      updateDoc(doc(await as('admin'), `${HOME}/members/m-unclaimed`), {
        displayName: 'Gogo Dube',
      }),
    );
    await givenData(async (db) => {
      await updateDoc(doc(db, `${HOME}/members/m-unclaimed`), { look: LOOK });
    });
    await assertSucceeds(
      updateDoc(doc(await as('admin'), `${HOME}/members/m-unclaimed`), { color: 'sky' }),
    );
  });
});

describe('the Wardrobe’s switch on the household', () => {
  it('lets family turn the shop off and on', async () => {
    await assertSucceeds(updateDoc(doc(await as('parent'), HOME), { avatarShop: false }));
    await assertSucceeds(updateDoc(doc(await as('admin'), HOME), { avatarShop: true }));
    await assertSucceeds(updateDoc(doc(await as('legacyMember'), HOME), { avatarShop: false }));
  });

  it('denies a kid, a kid device, a helper and a stranger', async () => {
    await assertFails(updateDoc(doc(await as('kid'), HOME), { avatarShop: false }));
    await assertFails(updateDoc(doc(await kidDevice(), HOME), { avatarShop: false }));
    await assertFails(updateDoc(doc(await as('cleaner'), HOME), { avatarShop: false }));
    await assertFails(updateDoc(doc(await asUser('uid-stranger'), HOME), { avatarShop: false }));
  });

  it('takes a boolean, and nothing else beside it from a parent', async () => {
    await assertFails(updateDoc(doc(await as('parent'), HOME), { avatarShop: 'off' }));
    await assertFails(
      updateDoc(doc(await as('parent'), HOME), { avatarShop: false, name: 'Ours' }),
    );
    await assertFails(
      updateDoc(doc(await as('parent'), HOME), {
        avatarShop: false,
        members: { 'uid-x': 'admin' },
      }),
    );
  });
});

describe('the creations switch on the household', () => {
  it('lets family turn AI creations off and on, beside the shop or alone', async () => {
    await assertSucceeds(updateDoc(doc(await as('parent'), HOME), { avatarCreationsOn: false }));
    await assertSucceeds(updateDoc(doc(await as('admin'), HOME), { avatarCreationsOn: true }));
    await assertSucceeds(
      updateDoc(doc(await as('admin'), HOME), { avatarCreationsOn: false, avatarShop: false }),
    );
  });

  it('denies a kid, a kid device, a helper and a stranger', async () => {
    for (const db of [
      await as('kid'),
      await kidDevice(),
      await as('cleaner'),
      await asUser('uid-stranger'),
    ]) {
      await assertFails(updateDoc(doc(db, HOME), { avatarCreationsOn: false }));
    }
  });

  it('takes a boolean, and nothing else beside it', async () => {
    await assertFails(updateDoc(doc(await as('parent'), HOME), { avatarCreationsOn: 'off' }));
    await assertFails(updateDoc(doc(await as('parent'), HOME), { avatarCreationsOn: 0 }));
    await assertFails(
      updateDoc(doc(await as('parent'), HOME), { avatarCreationsOn: false, name: 'Ours' }),
    );
  });
});
