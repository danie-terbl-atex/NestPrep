/**
 * The children's stars (chore points ADR-0001), through the Functions' own
 * code so the ledger, balances and streaks are what the app would have made:
 * each completion goes through `reconcileChore` (the body of the
 * `awardChorePoints` trigger), a parent's check through the same ledger step
 * `reviewChore` takes, a reward request through `reserveReward`. One chore is
 * left waiting for a parent's check, one reward waiting to be handed over.
 */
import { createRequire } from 'node:module';

import { writeAll } from './context.mjs';
import { WHO } from './cast.mjs';
import { taskId } from './todos.mjs';

const require = createRequire(import.meta.url);
const { FieldValue } = require('firebase-admin/firestore');
const { reconcileChore } = require('../../lib/chore_points/chore_reconcile.js');
const { readBalance, stageLine } = require('../../lib/chore_points/point_ledger.js');
const { reserveReward } = require('../../lib/chore_points/reward_reservation.js');

const { mom, dad, lerato, sipho } = WHO;

/** [task, occurrence (days from Monday), doer, checkedBy?] — in the order they were done. */
const CHORES_DONE = [
  ['tidy-room', -2, lerato, mom],
  ['fish', -2, sipho],
  ['fish', -1, sipho],
  ['table', -1, lerato],
  ['fish', 0, sipho],
  ['table', 0, lerato],
  ['bed-lerato', 0, lerato],
  ['bed-sipho', 0, sipho],
  ['clothes', 0, lerato],
  ['fish', 1, sipho],
  ['table', 1, lerato],
  ['bed-lerato', 1, lerato],
  ['clothes', 1, lerato],
  ['bed-sipho', 1, sipho],
  ['dishwasher', 1, lerato, dad],
  ['fish', 2, sipho],
  ['bed-lerato', 2, lerato],
  ['bed-sipho', 2, sipho],
  // Waits for a parent: the pending check on the Stars screen.
  ['toys', 2, sipho],
];

const REWARDS = [
  ['screen-time', '30 minutes extra screen time', 10, 'screenTime'],
  ['stickers', 'Sticker pack', 8, 'toy'],
  ['movie', 'Pick the Friday movie', 15, 'movie'],
  ['late-night', 'Stay up late on Saturday', 20, 'lateNight'],
  ['spur', 'Ice cream at the Spur', 25, 'iceCream'],
  ['book', 'A new book', 40, 'book'],
  ['gold-reef', 'Day at Gold Reef City', 100, 'outing'],
];

/** [id, reward, child, asked by] — a parent's ask is handed over at once. */
const REQUESTS = [
  ['stickers-sipho', 'stickers', sipho, mom],
  ['screen-lerato', 'screen-time', lerato, lerato],
];

/** A parent's "looks good": the ledger step of `reviewChore`, apart from its transport. */
async function approve(ctx, completionId, byMemberId, on) {
  const { store, cast } = ctx;
  const claims = ctx.col('pointClaims');
  return store.runTransaction(async (transaction) => {
    const claim = await transaction.get(claims.doc(completionId));
    if (!claim.exists || claim.get('status') !== 'pending') return false;
    const memberId = claim.get('memberId');
    const balance = await readBalance(transaction, store, cast.householdId, memberId);
    transaction.update(claim.ref, {
      status: 'awarded',
      settledAt: FieldValue.serverTimestamp(),
      settledBy: byMemberId,
    });
    stageLine(transaction, store, cast.householdId, balance, {
      entryId: `chore_${completionId}_${String(claim.get('round') ?? 1)}`,
      memberId,
      delta: claim.get('points'),
      kind: 'chore',
      sourceId: completionId,
      title: claim.get('title'),
      earnedOn: on,
    });
    return true;
  });
}

export async function seedStars(ctx) {
  const { day, at, col, cast, store } = ctx;
  await writeAll(
    store,
    REWARDS.map(([id, title, cost, icon]) => [
      col('rewards').doc(`demo-${id}`),
      { title, cost, icon, createdBy: mom, createdAt: at(day(-10), '20:00') },
    ]),
  );

  const outcomes = {};
  for (const [task, offset, doer, checkedBy] of CHORES_DONE) {
    const date = day(offset);
    const completionId = `${taskId(task)}_${date}`;
    const doneAt = offset >= 2 ? '07:15' : '17:00';
    await col('taskCompletions')
      .doc(completionId)
      .set({
        taskId: taskId(task),
        occurrenceDate: date,
        completedBy: doer,
        completedFor: doer,
        completedAt: at(date, doneAt),
      });
    // Reconciled as of when it was done, the way the trigger would have run
    // then, so each day's stars land on their day and the streak builds.
    const doneAtTime = at(date, doneAt).toDate();
    const outcome = await reconcileChore(store, cast.householdId, completionId, doneAtTime);
    outcomes[outcome] = (outcomes[outcome] ?? 0) + 1;
    if (checkedBy !== undefined && (await approve(ctx, completionId, checkedBy, date))) {
      outcomes.approved = (outcomes.approved ?? 0) + 1;
    }
  }

  const requests = {};
  for (const [id, reward, memberId, requestedBy] of REQUESTS) {
    const ref = col('rewardRequests').doc(`demo-${id}`);
    if (!(await ref.get()).exists) {
      await ref.set({
        rewardId: `demo-${reward}`,
        memberId,
        requestedBy,
        requestedAt: ctx.ago(requestedBy === mom ? 30 : 2),
      });
    }
    const outcome = await reserveReward(store, cast.householdId, ref.id);
    requests[outcome] = (requests[outcome] ?? 0) + 1;
  }
  const summary = (counts) =>
    Object.entries(counts)
      .map(([key, count]) => `${String(count)} ${key}`)
      .join(', ');
  return `stars: ${String(REWARDS.length)} rewards; chores ${summary(outcomes)}; requests ${summary(requests)}`;
}
