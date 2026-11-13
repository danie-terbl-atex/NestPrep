import { randomBytes } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

import { Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { DEFAULT_AI_SETTINGS, chargeOf } from '../../src/ai/ai_settings';
import { FirestoreUsageLedger } from '../../src/ai/firestore_usage_ledger';
import { STUCK_AFTER_MS, sweepStuckCreations } from '../../src/avatars/creation_sweep';
import { joinAs } from './account_data_fixture';
import {
  aFamily,
  addProfile,
  aMoment,
  household,
  read,
  settled,
  status,
  type Family,
  ZONE,
} from './chore_points_fixture';
import { eventually } from './product_analytics_fixture';
import {
  adminBucket,
  adminDb,
  adminStorage,
  callAs,
  clearFirestore,
  closeAdmin,
} from './emulator_harness';

/**
 * AI creations end to end (avatars ADR-0003, ADR-0005, ADR-0006): a request
 * written the way the app writes one wakes `onAvatarCreation`, which reads
 * the reference with the canned check, draws the canned picture, keeps it
 * with its original, charges the creations allowance and never the monthly
 * calls, and refunds whatever it could not finish.
 */

afterAll(closeAdmin);

let family: Family;

const REPLIES = adminDb().collection('aiEmulator');
const DRAWING = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46]);
const SQUARE = resolve(import.meta.dirname, '../../assets/emulator_avatar.jpg');
const WIDE = resolve(import.meta.dirname, '../../assets/emulator_portrait.jpg');
const CLEAN = { realisticHumanFace: false, logo: false, text: false };
const BUDDY = {
  creature: 'dragon',
  colour: 'pink',
  loves: 'pancakes',
  wears: 'cape',
  power: 'flying',
};

function reading(kind: string): string {
  return JSON.stringify({
    kind,
    hairColour: kind === 'drawing-of-person' ? 'yellow' : null,
    outfit: kind === 'drawing-of-person' ? 'a pink dress' : null,
    favouriteThings: ['a kite'],
    mood: 'happy',
  });
}

beforeEach(async () => {
  await clearFirestore();
  family = await aFamily();
  await REPLIES.doc('avatarDrawingCheck').set({ reply: reading('drawing-of-creature') });
  await REPLIES.doc('avatarPetCheck').set({ reply: reading('photo-of-pet') });
  await REPLIES.doc('avatarExtraCheck').set({ reply: JSON.stringify({ allowed: true }) });
  await REPLIES.doc('avatarResultCheck').set({ reply: JSON.stringify(CLEAN) });
});

async function premium(): Promise<void> {
  await household(family.householdId)
    .collection('entitlement')
    .doc('current')
    .set({ premiumUntil: Timestamp.fromMillis(Date.now() + 86_400_000) });
}

function prefix(memberId: string): string {
  return `households/${family.householdId}/avatars/${memberId}/`;
}

async function upload(memberId: string): Promise<string> {
  const inboxId = randomBytes(9).toString('base64url');
  for (const bucket of ['nestprep-643b7.appspot.com', 'nestprep-643b7.firebasestorage.app']) {
    await adminStorage()
      .bucket(bucket)
      .file(`${prefix(memberId)}inbox/${inboxId}.jpg`)
      .save(DRAWING, { contentType: 'image/jpeg', resumable: false });
  }
  return inboxId;
}

async function bytesAt(path: string): Promise<Buffer | null> {
  const file = adminBucket().file(path);
  const [exists] = await file.exists();
  if (!exists) return null;
  const [bytes] = await file.download();
  return bytes;
}

async function ask(
  creation: Record<string, unknown>,
  id = randomBytes(10).toString('hex'),
): Promise<{ id: string; outcome: Record<string, unknown> | undefined }> {
  await household(family.householdId)
    .collection('avatarCreations')
    .doc(id)
    .set({ requestedAt: new Date(), ...creation });
  const outcome = await settled(family, 'avatarCreations', id, (value) =>
    ['ready', 'refused', 'failed'].includes(String(status(value))),
  );
  return { id, outcome };
}

async function aDrawing(
  memberId = family.mia,
  extra: Record<string, unknown> = {},
): Promise<{ id: string; outcome: Record<string, unknown> | undefined }> {
  return ask({
    memberId,
    recipe: 'drawing',
    style: 'clay',
    inboxId: await upload(memberId),
    requestedBy: memberId,
    ...extra,
  });
}

async function usage(): Promise<{
  month: Record<string, unknown>;
  lifetime: Record<string, unknown>;
}> {
  const docs = await household(family.householdId).collection('aiUsage').get();
  const month = docs.docs.find((doc) => /^\d{4}-\d{2}$/.test(doc.id))?.data() ?? {};
  const lifetime = docs.docs.find((doc) => doc.id === 'lifetime')?.data() ?? {};
  return { month, lifetime };
}

describe('a drawing made real', () => {
  it('keeps the picture and its original, owned by the child, and spends the free household’s one', async () => {
    const { id, outcome } = await aDrawing();
    expect(outcome).toMatchObject({ status: 'ready', keepsakeId: id, left: 0 });
    const hash = String(outcome?.['imageHash']);
    expect(hash).toMatch(/^[0-9a-f]{32}$/);

    expect(await read(family, 'avatarKeepsakes', id)).toMatchObject({
      memberId: family.mia,
      recipe: 'drawing',
      style: 'clay',
      originalPath: `${prefix(family.mia)}keepsakes/${id}.jpg`,
      imageHash: hash,
      createdBy: family.mia,
    });
    expect(await read(family, 'memberAvatars', family.mia)).toMatchObject({
      owned: { images: [hash] },
    });
    expect(await bytesAt(`${prefix(family.mia)}${hash}.jpg`)).toEqual(await readFile(SQUARE));
    expect(await bytesAt(`${prefix(family.mia)}keepsakes/${id}.jpg`)).toEqual(DRAWING);
    const inbox = await adminBucket().getFiles({ prefix: `${prefix(family.mia)}inbox/` });
    expect(inbox[0]).toEqual([]);

    const { month, lifetime } = await usage();
    expect(month).toMatchObject({
      byFeature: { avatarCreate: 1 },
      allowanceAttempts: { avatarCreate: 3 },
    });
    expect(month['calls']).toBeUndefined();
    expect(month['attempts']).toBeUndefined();
    expect(lifetime).toMatchObject({ byFeature: { avatarCreate: 1 } });
  });

  it('then sends a free household to the paywall, and still deletes the reference', async () => {
    await aDrawing();
    const { outcome } = await aDrawing();
    expect(outcome).toMatchObject({ status: 'refused', reason: 'premiumRequired', left: 0 });
    const inbox = await adminBucket().getFiles({ prefix: `${prefix(family.mia)}inbox/` });
    expect(inbox[0]).toEqual([]);
  });

  it('draws a person drawing as a Nestling from words, and counts premium by the month', async () => {
    await premium();
    await REPLIES.doc('avatarDrawingCheck').set({ reply: reading('drawing-of-person') });
    const { outcome } = await aDrawing();
    expect(outcome).toMatchObject({ status: 'ready', left: 11 });
  });

  it('refuses a photo of a person, charges nothing, and deletes it', async () => {
    await REPLIES.doc('avatarDrawingCheck').set({ reply: reading('photo-of-person') });
    const { id, outcome } = await aDrawing();
    expect(outcome).toMatchObject({ status: 'refused', reason: 'notAllowed', left: 1 });
    expect(await read(family, 'avatarKeepsakes', id)).toBeUndefined();
    expect((await adminBucket().getFiles({ prefix: prefix(family.mia) }))[0]).toEqual([]);
    expect((await usage()).lifetime).toEqual({});
  });

  it('closes creations for the month after photo upon refused photo, and none of the household’s other AI', async () => {
    await REPLIES.doc('avatarDrawingCheck').set({ reply: reading('photo-of-person') });
    for (let attempt = 0; attempt < 7; attempt += 1) {
      expect((await aDrawing()).outcome).toMatchObject({ status: 'refused', reason: 'notAllowed' });
    }
    const closed = await aDrawing();
    expect(closed.outcome).toMatchObject({ status: 'refused', reason: 'limitReached', left: 1 });
    expect((await adminBucket().getFiles({ prefix: prefix(family.mia) }))[0]).toEqual([]);

    const { month, lifetime } = await usage();
    expect(month).toMatchObject({ allowanceAttempts: { avatarCreate: 7 } });
    expect(month['attempts']).toBeUndefined();
    expect(month['calls']).toBeUndefined();
    expect(lifetime).toEqual({});
  });

  it('refuses a picture the check finds a face in, and gives the creation back', async () => {
    await REPLIES.doc('avatarResultCheck').set({ reply: JSON.stringify({ ...CLEAN, text: true }) });
    const { id, outcome } = await aDrawing();
    expect(outcome).toMatchObject({ status: 'refused', reason: 'declined', left: 1 });
    expect(await read(family, 'avatarKeepsakes', id)).toBeUndefined();
    expect((await adminBucket().getFiles({ prefix: prefix(family.mia) }))[0]).toEqual([]);
    const { month, lifetime } = await usage();
    expect(month).toMatchObject({ byFeature: { avatarCreate: 0 } });
    expect(lifetime).toMatchObject({ byFeature: { avatarCreate: 0 } });
  });

  it('refuses a picture the model would not draw, and fails one it could not, both refunded', async () => {
    await REPLIES.doc('avatarCreate').set({ failWith: 'blocked' });
    expect((await aDrawing()).outcome).toMatchObject({ status: 'refused', reason: 'declined' });
    await REPLIES.doc('avatarCreate').set({ failWith: 'permanent' });
    expect((await aDrawing()).outcome).toMatchObject({ status: 'failed', reason: 'unavailable' });
    await REPLIES.doc('avatarCreate').delete();
    expect((await usage()).lifetime).toMatchObject({ byFeature: { avatarCreate: 0 } });
    expect((await aDrawing()).outcome).toMatchObject({ status: 'ready' });
  });

  it('is off while family has switched creations off', async () => {
    await household(family.householdId).update({ avatarCreationsOn: false });
    expect((await aDrawing()).outcome).toMatchObject({ status: 'refused', reason: 'creationsOff' });
    await household(family.householdId).update({ avatarCreationsOn: true });
    expect((await aDrawing()).outcome).toMatchObject({ status: 'ready' });
  });

  it('does nothing for a request that already has a status', async () => {
    const id = 'settled-already';
    await household(family.householdId).collection('avatarCreations').doc(id).set({
      memberId: family.mia,
      recipe: 'buddy',
      buddy: BUDDY,
      requestedBy: family.mia,
      requestedAt: new Date(),
      status: 'checking',
    });
    await aMoment();
    expect(await read(family, 'avatarCreations', id)).toMatchObject({ status: 'checking' });
    expect((await usage()).month).toEqual({});
  });
});

describe('a creation a dead run left behind', () => {
  const ledger = (): FirestoreUsageLedger => new FirestoreUsageLedger(adminDb());
  const objects = {
    deleteObjects: async (paths: readonly string[]): Promise<void> => {
      await Promise.all(
        paths.map((path) => adminBucket().file(path).delete({ ignoreNotFound: true })),
      );
    },
  };
  const sweep = (now: Date): ReturnType<typeof sweepStuckCreations> =>
    sweepStuckCreations({ store: adminDb(), objects, ledger: ledger() }, now);
  const later = (): Date => new Date(Date.now() + STUCK_AFTER_MS + 60_000);

  async function stuck(status: string, extra: Record<string, unknown> = {}): Promise<string> {
    const id = randomBytes(10).toString('hex');
    const inboxId = await upload(family.mia);
    await household(family.householdId)
      .collection('avatarCreations')
      .doc(id)
      .set({
        memberId: family.mia,
        recipe: 'drawing',
        inboxId,
        requestedBy: family.mia,
        requestedAt: new Date(),
        status,
        ...extra,
      });
    await ledger().claim({
      householdId: family.householdId,
      timeZone: ZONE,
      feature: 'avatarCreate',
      uid: family.mia,
      now: new Date(),
      monthlyCalls: DEFAULT_AI_SETTINGS.monthlyCalls,
      charge: chargeOf(DEFAULT_AI_SETTINGS, 'avatarCreate'),
    });
    return id;
  }

  async function callStatuses(): Promise<unknown[]> {
    const calls = await adminDb().collectionGroup('calls').get();
    return calls.docs
      .filter((call) => call.ref.path.startsWith(`households/${family.householdId}/`))
      .map((call) => call.get('status') as unknown);
  }

  it('is left alone inside its hour', async () => {
    const id = await stuck('drawing');
    expect(await sweep(new Date())).toEqual({ failed: 0, ready: 0, refunded: 0 });
    expect(await read(family, 'avatarCreations', id)).toMatchObject({ status: 'drawing' });
    expect((await usage()).lifetime).toMatchObject({ byFeature: { avatarCreate: 1 } });
    expect(
      (await adminBucket().getFiles({ prefix: `${prefix(family.mia)}inbox/` }))[0],
    ).toHaveLength(1);
  });

  it('fails after an hour, gives the creation back and deletes the reference, once', async () => {
    const id = await stuck('checking');
    await adminBucket()
      .file(`${prefix(family.mia)}keepsakes/${id}.jpg`)
      .save(DRAWING, {
        contentType: 'image/jpeg',
        resumable: false,
      });
    expect(await sweep(later())).toEqual({ failed: 1, ready: 0, refunded: 1 });

    const ended = await read(family, 'avatarCreations', id);
    expect(ended).toMatchObject({ status: 'failed', reason: 'unavailable' });
    expect(ended?.['settledAt']).toBeDefined();
    expect((await adminBucket().getFiles({ prefix: prefix(family.mia) }))[0]).toEqual([]);
    const { month, lifetime } = await usage();
    expect(month).toMatchObject({ byFeature: { avatarCreate: 0 } });
    expect(lifetime).toMatchObject({ byFeature: { avatarCreate: 0 } });
    expect(await callStatuses()).toEqual(['failed']);

    expect(await sweep(later())).toEqual({ failed: 0, ready: 0, refunded: 0 });
    expect((await usage()).lifetime).toMatchObject({ byFeature: { avatarCreate: 0 } });
    expect((await aDrawing()).outcome).toMatchObject({ status: 'ready' });
  });

  it('is ready when its picture was already kept, and stays charged', async () => {
    const id = await stuck('drawing', { imageHash: 'a'.repeat(32), keepsakeId: 'kept' });
    expect(await sweep(later())).toEqual({ failed: 0, ready: 1, refunded: 0 });
    const ended = await read(family, 'avatarCreations', id);
    expect(ended).toMatchObject({ status: 'ready' });
    expect(ended?.['reason']).toBeUndefined();
    expect((await usage()).lifetime).toMatchObject({ byFeature: { avatarCreate: 1 } });
    expect(await callStatuses()).toEqual(['claimed']);
    expect((await adminBucket().getFiles({ prefix: `${prefix(family.mia)}inbox/` }))[0]).toEqual(
      [],
    );
  });
});

describe('a pet twin and a buddy', () => {
  it('takes only a photo of a pet', async () => {
    const inboxId = await upload(family.mia);
    const asked = { memberId: family.mia, recipe: 'pet', inboxId, requestedBy: family.mia };
    await REPLIES.doc('avatarPetCheck').set({ reply: reading('drawing-of-creature') });
    expect((await ask(asked)).outcome).toMatchObject({ status: 'refused', reason: 'notAllowed' });
    await REPLIES.doc('avatarPetCheck').set({ reply: reading('photo-of-pet') });
    const again = { ...asked, inboxId: await upload(family.mia) };
    expect((await ask(again)).outcome).toMatchObject({ status: 'ready' });
  });

  it('builds a buddy from the chips, refuses words the check will not take, and keeps the chips', async () => {
    await premium();
    const buddy = { memberId: family.mia, recipe: 'buddy', buddy: BUDDY, requestedBy: family.mia };
    await REPLIES.doc('avatarExtraCheck').set({ reply: JSON.stringify({ allowed: false }) });
    expect((await ask({ ...buddy, extra: 'like Elsa' })).outcome).toMatchObject({
      status: 'refused',
      reason: 'notAllowed',
    });
    const { id, outcome } = await ask({ ...buddy, buddy: { ...BUDDY, creature: 'pikachu' } });
    expect(outcome).toMatchObject({ status: 'refused', reason: 'notAllowed' });
    expect(await read(family, 'avatarKeepsakes', id)).toBeUndefined();

    const made = await ask(buddy);
    expect(made.outcome).toMatchObject({ status: 'ready', left: 11 });
    expect(await read(family, 'avatarKeepsakes', made.id)).toMatchObject({
      recipe: 'buddy',
      style: 'plush',
      originalPath: null,
      buddy: BUDDY,
    });
  });
});

describe('the Nest portrait', () => {
  it('puts one wide picture in the frame album, stamped as the parent who asked, and keeps it', async () => {
    await premium();
    const { id, outcome } = await ask({
      memberId: family.samMember,
      recipe: 'portrait',
      requestedBy: family.samMember,
    });
    expect(outcome).toMatchObject({ status: 'ready', left: 11 });
    const hash = String(outcome?.['imageHash']);
    const album = adminBucket().file(`households/${family.householdId}/framePhotos/portrait-${id}`);
    const [metadata] = await album.getMetadata();
    expect(metadata.contentType).toBe('image/jpeg');
    expect(metadata.metadata).toMatchObject({ uploadedByUid: family.sam.uid });
    expect(Number(metadata.size)).toBeLessThanOrEqual(1024 * 1024);
    expect(await bytesAt(`${prefix(family.samMember)}${hash}.jpg`)).toEqual(await readFile(WIDE));
    expect(await read(family, 'avatarKeepsakes', id)).toMatchObject({
      memberId: family.samMember,
      recipe: 'portrait',
      style: null,
      originalPath: null,
    });
    expect(await read(family, 'memberAvatars', family.samMember)).toBeUndefined();
    expect((await usage()).month).toMatchObject({ byFeature: { avatarPortrait: 1 } });

    const told = await eventually(
      () => read(family, 'notificationInbox', `avatar_${id}`),
      (item) => item !== undefined,
    );
    expect(told).toMatchObject({
      memberId: family.samMember,
      category: 'chores',
      title: 'Your Nest portrait is ready',
    });
  });

  it('is premium only', async () => {
    const { outcome } = await ask({
      memberId: family.samMember,
      recipe: 'portrait',
      requestedBy: family.samMember,
    });
    expect(outcome).toMatchObject({ status: 'refused', reason: 'premiumRequired', left: 1 });
  });
});

describe('keepsakes and photos', () => {
  async function wear(memberId: string, base: string): Promise<void> {
    await household(family.householdId)
      .collection('memberAvatars')
      .doc(memberId)
      .set(
        { choice: { base, wear: {} }, updatedBy: family.samMember, updatedAt: new Date() },
        { merge: true },
      );
    await eventually(
      async () =>
        (await read(family, 'members', memberId))?.['look'] as Record<string, unknown> | undefined,
      (look) => look?.['base'] === (base === 'initial' ? null : base),
    );
  }

  it('takes a keepsake off the shelf, and the member it was worn by back to the initial first', async () => {
    const { id, outcome } = await aDrawing();
    const hash = String(outcome?.['imageHash']);
    await wear(family.mia, `image:${hash}`);

    await household(family.householdId)
      .collection('avatarKeepsakeDeletes')
      .doc(id)
      .set({ requestedBy: family.mia, requestedAt: new Date() });
    await settled(family, 'avatarKeepsakes', id, (value) => value === undefined);
    expect(await read(family, 'avatarKeepsakeDeletes', id)).toBeUndefined();
    expect(await read(family, 'memberAvatars', family.mia)).toMatchObject({
      choice: { base: 'initial' },
      owned: { images: [] },
    });
    expect(await read(family, 'members', family.mia)).toMatchObject({ look: { base: null } });
    expect(await bytesAt(`${prefix(family.mia)}${hash}.jpg`)).toBeNull();
    expect(await bytesAt(`${prefix(family.mia)}keepsakes/${id}.jpg`)).toBeNull();
  });

  it('deletes a photo once it is not worn, and keeps a creation that is not', async () => {
    await premium();
    const { outcome } = await aDrawing();
    const made = String(outcome?.['imageHash']);
    const photo = randomBytes(16).toString('hex');
    for (const bucket of ['nestprep-643b7.appspot.com', 'nestprep-643b7.firebasestorage.app']) {
      await adminStorage()
        .bucket(bucket)
        .file(`${prefix(family.mia)}${photo}.jpg`)
        .save(DRAWING, { contentType: 'image/jpeg', resumable: false });
    }
    await household(family.householdId)
      .collection('memberAvatars')
      .doc(family.mia)
      .set(
        {
          choice: { base: 'initial', wear: {} },
          pendingPhoto: photo,
          updatedBy: family.samMember,
          updatedAt: new Date(),
        },
        { merge: true },
      );
    await eventually(
      async () =>
        (await read(family, 'members', family.mia))?.['look'] as
          Record<string, unknown> | undefined,
      (look) => look?.['base'] === `image:${photo}`,
    );
    await wear(family.mia, 'preset:pip');
    const avatar = await settled(family, 'memberAvatars', family.mia, (value) => {
      const owned = value?.['owned'] as { images?: string[] } | undefined;
      return owned?.images?.includes(photo) === false;
    });
    expect(avatar?.['owned']).toMatchObject({ images: [made] });
    expect(
      await eventually(
        () => bytesAt(`${prefix(family.mia)}${photo}.jpg`),
        (b) => b === null,
      ),
    ).toBeNull();
    expect(await bytesAt(`${prefix(family.mia)}${made}.jpg`)).not.toBeNull();
  });

  it('go with a member who is removed, and with one who deletes their account', async () => {
    await premium();
    const gran = await addProfile(family.householdId, 'Gran', 'parent');
    const made = await aDrawing(gran, { requestedBy: family.samMember });
    expect(made.outcome).toMatchObject({ status: 'ready' });
    await callAs(family.sam, 'removeMember', { householdId: family.householdId, memberId: gran });
    expect(await read(family, 'avatarKeepsakes', made.id)).toBeUndefined();
    expect(await read(family, 'avatarCreations', made.id)).toBeUndefined();

    const alex = await addProfile(family.householdId, 'Alex', 'parent');
    const alexAccount = await joinAs(family.sam, family.householdId, alex);
    const theirs = await aDrawing(alex, { requestedBy: family.samMember });
    expect(theirs.outcome).toMatchObject({ status: 'ready' });
    await callAs(alexAccount, 'deleteAccount', { confirmation: 'DELETE', endingHouseholdIds: [] });
    expect(await read(family, 'avatarKeepsakes', theirs.id)).toBeUndefined();
    expect(await read(family, 'avatarCreations', theirs.id)).toBeUndefined();
    expect((await adminBucket().getFiles({ prefix: prefix(alex) }))[0]).toEqual([]);
  });
});
