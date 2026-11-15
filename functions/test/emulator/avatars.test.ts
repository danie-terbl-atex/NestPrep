import { randomBytes } from 'node:crypto';

import { Timestamp, type DocumentReference } from 'firebase-admin/firestore';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import {
  aChore,
  aFamily,
  addProfile,
  aMoment,
  expectBalance,
  household,
  read,
  settled,
  status,
  tick,
  type Family,
} from './chore_points_fixture';
import { joinAs } from './account_data_fixture';
import { eventually } from './product_analytics_fixture';
import {
  adminDb,
  adminStorage,
  callAs,
  clearFirestore,
  closeAdmin,
  httpFunctionUrl,
} from './emulator_harness';

/**
 * Avatars end to end (avatars ADR-0001, ADR-0004, C-0023 rev 18): a choice
 * written the way the app writes one wakes `onMemberAvatarWritten`, which
 * mirrors the look onto the member; stars hatch and grow a Nestling in the
 * same transaction as the ledger; the Wardrobe sells with stars; and the
 * frame draws what the server resolved.
 */

afterAll(closeAdmin);

let family: Family;

beforeEach(async () => {
  await clearFirestore();
  family = await aFamily();
});

const HASH = randomBytes(16).toString('hex');
const JPEG = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46]);

async function choose(
  memberId: string,
  choice: Record<string, unknown>,
  extra: Record<string, unknown> = {},
): Promise<void> {
  await household(family.householdId)
    .collection('memberAvatars')
    .doc(memberId)
    .set({ choice, updatedBy: family.samMember, updatedAt: new Date(), ...extra }, { merge: true });
}

async function lookOf(memberId: string): Promise<unknown> {
  return (await read(family, 'members', memberId))?.['look'];
}

async function settledLook(
  memberId: string,
  isReady: (look: Record<string, unknown> | undefined) => boolean,
): Promise<Record<string, unknown> | undefined> {
  return eventually(
    async () => (await lookOf(memberId)) as Record<string, unknown> | undefined,
    isReady,
  );
}

async function putAvatar(
  memberId: string,
  hash: string,
  bytes: Buffer = JPEG,
  contentType = 'image/jpeg',
): Promise<void> {
  for (const bucket of ['nestprep-643b7.appspot.com', 'nestprep-643b7.firebasestorage.app']) {
    await adminStorage()
      .bucket(bucket)
      .file(`households/${family.householdId}/avatars/${memberId}/${hash}.jpg`)
      .save(bytes, { contentType, resumable: false });
  }
}

async function buy(
  purchaseId: string,
  accessoryId: string,
  memberId = family.mia,
): Promise<Record<string, unknown> | undefined> {
  await household(family.householdId).collection('avatarPurchases').doc(purchaseId).set({
    memberId,
    accessoryId,
    requestedBy: memberId,
    requestedAt: new Date(),
  });
  return settled(family, 'avatarPurchases', purchaseId, (value) => status(value) !== undefined);
}

describe('a look mirrored from a choice', () => {
  it('puts a kid’s Nestling on their profile as an egg, and their first star hatches it', async () => {
    await choose(family.mia, { base: 'preset:pip', wear: { top: 'acc-cap' } });
    expect(await settledLook(family.mia, (look) => look !== undefined)).toEqual({
      v: 1,
      base: 'preset:pip',
      stage: 0,
      wear: { top: 'acc-cap' },
    });

    await aChore(family, 'bed');
    await tick(family, 'bed');
    await expectBalance(family, family.mia, 5);
    expect(await settledLook(family.mia, (look) => look?.['stage'] === 1)).toMatchObject({
      base: 'preset:pip',
      stage: 1,
    });
  });

  it('gives an adult the stage they choose, and a grown bird when they choose none', async () => {
    await choose(family.samMember, { base: 'preset:olive', wear: { face: 'acc-round-glasses' } });
    expect(await settledLook(family.samMember, (look) => look !== undefined)).toEqual({
      v: 1,
      base: 'preset:olive',
      stage: 3,
      wear: { face: 'acc-round-glasses' },
    });
    await choose(family.samMember, { base: 'preset:olive', stage: 1, wear: {} });
    expect(await settledLook(family.samMember, (look) => look?.['stage'] === 1)).toMatchObject({
      stage: 1,
      wear: {},
    });
  });

  it('lets a grown-up wear any accessory unowned, while a kid must buy it', async () => {
    await choose(family.samMember, { base: 'preset:olive', wear: { top: 'acc-crown' } });
    expect(await settledLook(family.samMember, (look) => look !== undefined)).toMatchObject({
      wear: { top: 'acc-crown' },
    });
    expect(await read(family, 'memberAvatars', family.samMember)).not.toHaveProperty('owned');

    await choose(family.mia, { base: 'preset:pip', wear: { top: 'acc-crown' } });
    const reverted = await settled(family, 'memberAvatars', family.mia, (value) => {
      const choice = value?.['choice'] as { wear?: Record<string, unknown> } | undefined;
      return choice?.wear?.['top'] === undefined;
    });
    expect(reverted?.['choice']).toEqual({ base: 'initial', wear: {} });
  });

  it('takes an invalid choice back to the last valid one, and stops there', async () => {
    await choose(family.mia, { base: 'preset:pip', wear: {} });
    await settledLook(family.mia, (look) => look !== undefined);
    await choose(family.mia, { base: 'preset:pip', wear: { top: 'acc-crown' } });
    const reverted = await settled(family, 'memberAvatars', family.mia, (value) => {
      const choice = value?.['choice'] as { wear?: Record<string, unknown> } | undefined;
      return choice?.wear?.['top'] === undefined;
    });
    expect(reverted?.['choice']).toEqual({ base: 'preset:pip', wear: {} });
    expect(await lookOf(family.mia)).toEqual({ v: 1, base: 'preset:pip', stage: 0, wear: {} });
    const before = (
      await household(family.householdId).collection('memberAvatars').doc(family.mia).get()
    ).updateTime;
    await aMoment();
    const after = (
      await household(family.householdId).collection('memberAvatars').doc(family.mia).get()
    ).updateTime;
    expect(after?.toMillis()).toBe(before?.toMillis());
  });

  it('owns and chooses a photo that is a small JPEG, and refuses one that is not', async () => {
    await putAvatar(family.mia, HASH);
    await choose(
      family.mia,
      { base: 'preset:pip', wear: { face: 'acc-round-glasses', top: 'acc-cap' } },
      { pendingPhoto: HASH },
    );
    const taken = await settled(
      family,
      'memberAvatars',
      family.mia,
      (value) => value?.['pendingPhoto'] === undefined,
    );
    expect(taken).toMatchObject({
      choice: { base: `image:${HASH}`, wear: { top: 'acc-cap' } },
      owned: { images: [HASH] },
    });
    expect(await settledLook(family.mia, (look) => look?.['base'] === `image:${HASH}`)).toEqual({
      v: 1,
      base: `image:${HASH}`,
      stage: 0,
      wear: { top: 'acc-cap' },
    });

    const big = randomBytes(16).toString('hex');
    await putAvatar(family.mia, big, Buffer.alloc(512 * 1024 + 1, 1));
    await choose(family.mia, { base: `image:${HASH}`, wear: {} }, { pendingPhoto: big });
    const refused = await settled(
      family,
      'memberAvatars',
      family.mia,
      (value) => value?.['pendingPhoto'] === undefined,
    );
    expect(refused?.['owned']).toMatchObject({ images: [HASH] });
    const missing = randomBytes(16).toString('hex');
    await choose(family.mia, { base: `image:${missing}`, wear: {} });
    const notOwned = await settled(family, 'memberAvatars', family.mia, (value) => {
      const choice = value?.['choice'] as { base?: string } | undefined;
      return choice?.base !== `image:${missing}`;
    });
    expect(notOwned?.['choice']).toMatchObject({ base: `image:${HASH}` });
  });

  it('takes the later of two photos offered one straight after the other', async () => {
    const later = randomBytes(16).toString('hex');
    await putAvatar(family.mia, HASH);
    await putAvatar(family.mia, later);
    const initial = { base: 'initial', wear: {} };
    await choose(family.mia, initial, { pendingPhoto: HASH });
    await choose(family.mia, initial, { pendingPhoto: later });
    const taken = await settled(family, 'memberAvatars', family.mia, (value) => {
      const choice = value?.['choice'] as { base?: string } | undefined;
      return value?.['pendingPhoto'] === undefined && choice?.base !== 'initial';
    });
    expect(taken?.['choice']).toMatchObject({ base: `image:${later}` });
  });
});

describe('the Wardrobe', () => {
  const entitlement = (): DocumentReference =>
    household(family.householdId).collection('entitlement').doc('current');

  beforeEach(async () => {
    await entitlement().set({ premiumUntil: Timestamp.fromMillis(Date.now() + 86_400_000) });
    await aChore(family, 'bed', { points: 25 });
    await tick(family, 'bed');
    await expectBalance(family, family.mia, 25);
  });

  it('sells an accessory for stars, at once, and it can then be worn', async () => {
    expect(await buy('crown', 'acc-crown')).toMatchObject({ status: 'owned' });
    await expectBalance(family, family.mia, 5);
    expect(await read(family, 'pointEntries', 'accessory_crown')).toMatchObject({
      kind: 'accessory',
      delta: -20,
      title: 'Crown',
      memberId: family.mia,
    });
    expect(await read(family, 'pointBalances', family.mia)).toMatchObject({
      spent: 20,
      earned: 25,
    });
    expect(await read(family, 'memberAvatars', family.mia)).toMatchObject({
      owned: { accessories: ['acc-crown'] },
    });
    await choose(family.mia, { base: 'preset:pip', wear: { top: 'acc-crown' } });
    expect(await settledLook(family.mia, (look) => look !== undefined)).toMatchObject({
      wear: { top: 'acc-crown' },
      stage: 1,
    });
  });

  it('refuses what cannot be bought, and says why', async () => {
    expect(await buy('again-1', 'acc-crown')).toMatchObject({ status: 'owned' });
    expect(await buy('again-2', 'acc-crown')).toMatchObject({
      status: 'refused',
      reason: 'alreadyOwned',
    });
    expect(await buy('dear', 'acc-star-crown')).toMatchObject({
      status: 'refused',
      reason: 'notEnoughStars',
    });
    expect(await buy('free', 'acc-cap')).toMatchObject({
      status: 'refused',
      reason: 'alreadyOwned',
    });
    expect(await buy('made-up', 'acc-jetpack')).toMatchObject({
      status: 'refused',
      reason: 'unknownAccessory',
    });
    expect(await buy('grown-up', 'acc-heart', family.samMember)).toMatchObject({
      status: 'refused',
      reason: 'notAKid',
    });
    await expectBalance(family, family.mia, 5);
  });

  it('sells nothing to a household without Premium, and takes no stars', async () => {
    await entitlement().delete();
    expect(await buy('free-tier', 'acc-crown')).toMatchObject({
      status: 'refused',
      reason: 'premiumRequired',
    });
    await entitlement().set({ premiumUntil: Timestamp.fromMillis(Date.now() - 60_000) });
    expect(await buy('lapsed', 'acc-crown')).toMatchObject({
      status: 'refused',
      reason: 'premiumRequired',
    });
    await expectBalance(family, family.mia, 25);
    expect((await read(family, 'memberAvatars', family.mia))?.['owned']).toBeUndefined();
  });

  it('is shut while family has switched the shop off', async () => {
    await household(family.householdId).update({ avatarShop: false });
    expect(await buy('shut', 'acc-heart')).toMatchObject({ status: 'refused', reason: 'shopOff' });
    await expectBalance(family, family.mia, 25);
    await household(family.householdId).update({ avatarShop: true });
    expect(await buy('open', 'acc-heart')).toMatchObject({ status: 'owned' });
    await expectBalance(family, family.mia, 20);
  });
});

async function linkedFrame(): Promise<string> {
  const secret = randomBytes(32).toString('base64url');
  const { code } = await callAs<{ code: string }>(null, 'startFramePairing', {
    secret,
    model: 'Frameo 10',
  });
  await callAs(family.sam, 'claimFramePairing', {
    householdId: family.householdId,
    code,
    name: 'Kitchen',
    panels: { calendar: false, todos: false, meals: false, helperMemberId: null },
  });
  return secret;
}

function avatarOf(body: unknown): Promise<Response> {
  return fetch(httpFunctionUrl('getFrameAvatar'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
}

describe('avatars on the frame (C-0023 rev 18)', () => {
  it('draws each member’s resolved avatar, and serves only a current member’s picture', async () => {
    await putAvatar(family.samMember, HASH);
    await choose(family.mia, { base: 'preset:pip', wear: { badge: 'acc-star' } });
    await choose(family.samMember, { base: 'initial', wear: {} }, { pendingPhoto: HASH });
    await settledLook(family.samMember, (look) => look?.['base'] === `image:${HASH}`);
    await settledLook(family.mia, (look) => look !== undefined);

    const secret = await linkedFrame();
    const day = await callAs<{ household: { members: Record<string, unknown>[] } }>(
      null,
      'getFrameDay',
      { secret },
    );
    const [mia, sam] = day.household.members;
    expect(mia).toMatchObject({
      name: 'Mia',
      kid: true,
      avatar: { base: { preset: 'nestling-pip-0' } },
    });
    expect(mia?.['avatar']).toHaveProperty(
      'layers',
      expect.arrayContaining([{ slot: 'badge', id: 'acc-star' }]),
    );
    expect(sam).toMatchObject({ name: 'Sam', avatar: { base: { image: HASH } } });
    expect(JSON.stringify(day)).not.toContain(family.mia);

    const served = await avatarOf({ secret, id: HASH });
    expect(served.status).toBe(200);
    expect(served.headers.get('content-type')).toBe('image/jpeg');
    expect(served.headers.get('cache-control')).toContain('no-store');
    expect(Buffer.from(await served.arrayBuffer())).toEqual(JPEG);

    expect((await avatarOf({ secret, id: randomBytes(16).toString('hex') })).status).toBe(404);
    expect(
      (await avatarOf({ secret: randomBytes(32).toString('base64url'), id: HASH })).status,
    ).toBe(410);
    expect((await avatarOf({ secret })).status).toBe(400);

    await choose(family.samMember, { base: 'preset:olive', wear: {} });
    await settledLook(family.samMember, (look) => look?.['base'] === 'preset:olive');
    expect((await avatarOf({ secret, id: HASH })).status).toBe(404);
  });
});

describe('an initial on the frame (C-0023 rev 19)', () => {
  it('sends the initial with what is worn for a member who chose it, and nothing for one with no look', async () => {
    await choose(family.samMember, { base: 'initial', wear: { top: 'acc-cap' } });
    await settledLook(family.samMember, (look) => look !== undefined);
    const secret = await linkedFrame();
    const day = await callAs<{ household: { members: Record<string, unknown>[] } }>(
      null,
      'getFrameDay',
      { secret },
    );
    const [mia, sam] = day.household.members;
    expect(mia).not.toHaveProperty('avatar');
    expect(sam?.['avatar']).toEqual({
      base: { initial: true },
      layers: [{ slot: 'top', id: 'acc-cap' }],
    });
  });
});

describe('a member who goes', () => {
  it('takes their look, what they own and their pictures with them', async () => {
    const gran = await addProfile(family.householdId, 'Gran', 'parent');
    await putAvatar(gran, HASH);
    await choose(gran, { base: 'initial', wear: {} }, { pendingPhoto: HASH });
    await settledLook(gran, (look) => look?.['base'] === `image:${HASH}`);

    await callAs(family.sam, 'removeMember', { householdId: family.householdId, memberId: gran });
    expect(await read(family, 'memberAvatars', gran)).toBeUndefined();
    const [left] = await adminStorage()
      .bucket('nestprep-643b7.firebasestorage.app')
      .getFiles({ prefix: `households/${family.householdId}/avatars/${gran}/` });
    expect(left).toEqual([]);
    expect(
      (await adminDb().doc(`households/${family.householdId}/members/${gran}`).get()).exists,
    ).toBe(false);
  });

  it('who deletes their account leaves a profile with no look and no pictures', async () => {
    const alex = await addProfile(family.householdId, 'Alex', 'parent');
    const alexAccount = await joinAs(family.sam, family.householdId, alex);
    await putAvatar(alex, HASH);
    await choose(alex, { base: 'initial', wear: {} }, { pendingPhoto: HASH });
    await settledLook(alex, (look) => look?.['base'] === `image:${HASH}`);

    await callAs(alexAccount, 'deleteAccount', { confirmation: 'DELETE', endingHouseholdIds: [] });
    const profile = await read(family, 'members', alex);
    expect(profile).toBeDefined();
    expect(profile).not.toHaveProperty('look');
    expect(await read(family, 'memberAvatars', alex)).toBeUndefined();
    const [left] = await adminStorage()
      .bucket('nestprep-643b7.firebasestorage.app')
      .getFiles({ prefix: `households/${family.householdId}/avatars/${alex}/` });
    expect(left).toEqual([]);
  });
});
