/**
 * The family's looks (avatars ADR-0001, ADR-0004), through the Functions' own
 * code: a purchase goes through `settleAvatarPurchase` (the body of
 * `onAvatarPurchase`), so the stars and the history read as the Wardrobe
 * would have left them, and each choice through `settleMemberAvatar` (the
 * body of `onMemberAvatarWritten`), which mirrors the look onto the member
 * with a kid's stage from their stars. Safe to run again: a settled purchase
 * stays settled, and a mirrored look is left alone.
 */
import { createRequire } from 'node:module';

import { WHO } from './cast.mjs';

const require = createRequire(import.meta.url);
const { FieldValue } = require('firebase-admin/firestore');
const { settleAvatarPurchase } = require('../../lib/avatars/avatar_purchase.js');
const { settleMemberAvatar } = require('../../lib/avatars/member_avatar.js');
const { readBalance, stageLine } = require('../../lib/chore_points/point_ledger.js');

/** No choice here waits on a photo, so nothing is looked up in Storage. */
const NO_PHOTOS = { list: async () => [] };

const { mom, dad, gran, lerato, sipho, zoe } = WHO;

/**
 * Who looks like what: Lerato a fledgling in the flower crown she bought,
 * Zoë still an egg, and Naledi grown, in glasses.
 */
export const CLOUD_LOOKS = {
  chosenBy: mom,
  purchases: [
    { id: 'demo-lerato-flower-crown', memberId: lerato, accessoryId: 'acc-flower-crown' },
  ],
  looks: [
    { memberId: lerato, choice: { base: 'preset:pip', wear: { top: 'acc-flower-crown' } } },
    { memberId: sipho, choice: { base: 'preset:mango', wear: { badge: 'acc-football' } } },
    { memberId: zoe, choice: { base: 'preset:cotton', wear: {} } },
    {
      memberId: mom,
      choice: { base: 'preset:sunny', stage: 3, wear: { face: 'acc-round-glasses' } },
    },
    { memberId: dad, choice: { base: 'preset:bramble', stage: 3, wear: { top: 'acc-cap' } } },
    { memberId: gran, choice: { base: 'preset:clover', stage: 3, wear: { badge: 'acc-book' } } },
  ],
};

/**
 * Stars for a household with no chores of its own (the emulator's): a line on
 * each of [dates], which are consecutive, so a streak — and a Nestling — grew.
 */
export async function earnStars(store, householdId, memberId, { dates, each, title }) {
  for (const date of dates) {
    await store.runTransaction(async (transaction) => {
      const entry = store.doc(
        `households/${householdId}/pointEntries/demo-stars_${memberId}_${date}`,
      );
      if ((await transaction.get(entry)).exists) return;
      const balance = await readBalance(transaction, store, householdId, memberId);
      stageLine(transaction, store, householdId, balance, {
        entryId: entry.id,
        memberId,
        delta: each,
        kind: 'chore',
        sourceId: 'demo-stars',
        title,
        earnedOn: date,
      });
    });
  }
}

export async function seedLooks(store, householdId, plan) {
  const household = store.collection('households').doc(householdId);
  const bought = {};
  for (const { id, memberId, accessoryId } of plan.purchases) {
    const ref = household.collection('avatarPurchases').doc(id);
    if (!(await ref.get()).exists) {
      await ref.set({
        memberId,
        accessoryId,
        requestedBy: memberId,
        requestedAt: FieldValue.serverTimestamp(),
      });
    }
    const outcome = await settleAvatarPurchase(store, householdId, id);
    bought[outcome] = (bought[outcome] ?? 0) + 1;
  }
  const mirrored = {};
  for (const { memberId, choice } of plan.looks) {
    await household
      .collection('memberAvatars')
      .doc(memberId)
      .set(
        { choice, updatedBy: plan.chosenBy, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    const outcome = await settleMemberAvatar(store, NO_PHOTOS, householdId, memberId);
    mirrored[outcome] = (mirrored[outcome] ?? 0) + 1;
  }
  const summary = (counts) =>
    Object.entries(counts)
      .map(([key, count]) => `${String(count)} ${key}`)
      .join(', ');
  return `avatars: purchases ${summary(bought)}; looks ${summary(mirrored)}`;
}

/** After `seedStars`, so Lerato has the stars for her crown and the kids their stages. */
export async function seedAvatars(ctx) {
  return seedLooks(ctx.store, ctx.cast.householdId, CLOUD_LOOKS);
}
