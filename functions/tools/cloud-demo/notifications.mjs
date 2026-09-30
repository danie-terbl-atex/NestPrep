/**
 * Notifications (notifications ADR-0001 to ADR-0003): each adult's settings
 * with a 06:30 digest, today's morning digest composed from the seeded week
 * by the Functions' own loader and composer, and the "chore to check" and
 * "reward asked" items — all through `deliverDrafts`, the one door every
 * producer uses. Push goes through a sender that sends nothing: a demo
 * account with no phone gets `noDevice`, exactly as the real job would mark it.
 *
 * Only the demo household is read or written; the real `runMorningDigest`
 * is not called, because it looks at every household that is due.
 */
import { createRequire } from 'node:module';

import { writeAll } from './context.mjs';

const require = createRequire(import.meta.url);
const { loadRoster, recipientIn } = require('../../lib/notifications/household_roster.js');
const { loadHouseholdDay } = require('../../lib/notifications/digest_loader.js');
const { composeDigest } = require('../../lib/notifications/digest_composer.js');
const { deliverDrafts } = require('../../lib/notifications/inbox_delivery.js');
const { digestId } = require('../../lib/notifications/morning_digest.js');
const {
  deliverChoreCheck,
  deliverRewardAsked,
} = require('../../lib/notifications/chore_delivery.js');

/** Pushes nothing and says so; no demo account has a phone registered. */
const QUIET_SENDER = {
  send: async () => ({ delivered: 0, invalidTokens: [], retryable: false }),
};

const DIGEST_MINUTE = 390;

async function composeTodaysDigests(ctx, roster, memberIds) {
  const people = memberIds.map((id) => recipientIn(roster, id)).filter(Boolean);
  const day = await loadHouseholdDay({
    store: ctx.store,
    roster,
    today: ctx.today,
    now: ctx.now,
    due: people,
  });
  const drafts = people.flatMap((recipient) => {
    const digest = composeDigest(day, recipient);
    if (digest === null) return [];
    const id = digestId(recipient.memberId, ctx.today);
    return [
      {
        id,
        memberId: recipient.memberId,
        category: 'digest',
        text: digest.push,
        detail: null,
        sections: digest.sections,
        target: { kind: 'inboxItem', id },
        source: { kind: 'digest', id: ctx.today },
        localDate: ctx.today,
      },
    ];
  });
  const report = await deliverDrafts(
    {
      store: ctx.store,
      sender: QUIET_SENDER,
      householdId: roster.householdId,
      zone: roster.zone,
      now: ctx.now,
    },
    drafts,
  );
  return report.created;
}

export async function seedNotifications(ctx) {
  const { cast, col, store } = ctx;
  const adults = cast.people.map((person) => person.memberId);
  await writeAll(
    store,
    adults.map((memberId) => [
      col('notificationSettings').doc(memberId),
      {
        digest: { enabled: true, minute: DIGEST_MINUTE },
        digestSlot: DIGEST_MINUTE / 15,
        categories: {
          documents: true,
          handover: true,
          chores: true,
          photos: true,
          coParenting: true,
        },
        quietHours: { enabled: true, startMinute: 1260, endMinute: 360 },
        updatedBy: memberId,
        updatedAt: ctx.at(ctx.day(-14), '20:00'),
      },
    ]),
  );

  const roster = await loadRoster(store, cast.householdId);
  if (roster === null) throw new Error('the demo household did not load as a roster');
  const digests = await composeTodaysDigests(ctx, roster, adults);

  let asks = 0;
  const pending = await col('pointClaims').where('status', '==', 'pending').get();
  for (const claim of pending.docs) {
    const report = await deliverChoreCheck(store, QUIET_SENDER, {
      householdId: cast.householdId,
      documentId: claim.id,
      before: undefined,
      after: claim.data(),
      now: ctx.now,
    });
    asks += report?.created ?? 0;
  }
  const waiting = await col('rewardRequests').where('status', '==', 'waiting').get();
  for (const request of waiting.docs) {
    const report = await deliverRewardAsked(store, QUIET_SENDER, {
      householdId: cast.householdId,
      documentId: request.id,
      before: undefined,
      after: request.data(),
      now: ctx.now,
    });
    asks += report?.created ?? 0;
  }
  // A chore a parent has since checked keeps its notice, read — the way it
  // looks once somebody has acted on it.
  const settled = [];
  for (const item of (await col('notificationInbox').where('category', '==', 'chores').get())
    .docs) {
    const source = item.get('source');
    if (source?.kind !== 'pointClaim' || item.get('readAt') !== null) continue;
    const claim = await col('pointClaims').doc(source.id).get();
    if (claim.get('status') !== 'pending') settled.push(item.ref);
  }
  for (const ref of settled) await ref.update({ readAt: ctx.now });
  return `notifications: settings for ${String(adults.length)} adults, ${String(digests)} digests today, ${String(asks)} chore/reward items (the Functions add handover and photo items)`;
}
