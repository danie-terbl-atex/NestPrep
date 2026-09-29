import { beforeEach, describe, expect, it } from 'vitest';

import { expectRefusal, householdOfTwo } from './calendar_sync_fixture';
import { adminDb, callAs, clearFirestore, signUp } from './emulator_harness';
import { HOME, PAT, SAM, givenTheHousehold, inbox, pushOf } from './notifications_fixture';
import { eventually } from './product_analytics_fixture';

/**
 * The deployed triggers and the one callable, in the Functions emulator
 * (notifications ADR-0001, BE-14): a handover, a chore to check and a reward
 * asked for each reach the family's inbox the moment they are written; the
 * test push goes only to its caller. The household has no phones here, so
 * nothing reaches for the real FCM — the inbox is what is asserted.
 */

beforeEach(async () => {
  await clearFirestore();
  await givenTheHousehold({ withPhones: false });
});

const inboxOf =
  (category: string): (() => Promise<Record<string, unknown>[]>) =>
  async () =>
    (await inbox()).filter((item) => item['category'] === category);

describe('the triggers', () => {
  it('a shift summary written pending reaches the family, and is marked sent', async () => {
    await adminDb()
      .doc(`${HOME}/nannyShiftSummaries/shift-9`)
      .set({
        carerMemberId: 'm-nomsa',
        entryCount: 2,
        delivery: { state: 'pending' },
      });
    const items = await eventually(inboxOf('handover'), (found) => found.length === 2);
    expect(items.map((item) => item['memberId']).sort()).toEqual([PAT.member, SAM.member]);
    expect(items.every((item) => pushOf(item).state === 'noDevice')).toBe(true);
    const summary = await eventually(
      async () => (await adminDb().doc(`${HOME}/nannyShiftSummaries/shift-9`).get()).data(),
      (value) => (value?.['delivery'] as { state?: string } | undefined)?.state === 'sent',
    );
    expect((summary?.['delivery'] as { state: string }).state).toBe('sent');
  });

  it('a chore that starts waiting for a check reaches the family, once', async () => {
    const claim = adminDb().doc(`${HOME}/pointClaims/bed_2026-09-29`);
    await claim.set({
      memberId: 'm-mia',
      taskId: 'bed',
      occurrenceDate: '2026-09-29',
      title: 'Make your bed',
      points: 3,
      status: 'pending',
      round: 1,
    });
    const items = await eventually(inboxOf('chores'), (found) => found.length === 2);
    expect(items.map((item) => item['id']).sort()).toEqual([
      'chore_bed_2026-09-29_1_m-pat',
      'chore_bed_2026-09-29_1_m-sam',
    ]);
    expect(items[0]?.['detail']).toBe('Mia · Make your bed');
    await claim.update({ points: 3 });
    await new Promise((resolve) => setTimeout(resolve, 1500));
    expect(await inboxOf('chores')()).toHaveLength(2);
  });

  it('a reward request moving to waiting reaches the family', async () => {
    // Written as the reservation leaves it — status and cost already set — so
    // `reserveRewardPoints` has nothing to decide and only this is heard.
    await adminDb().doc(`${HOME}/rewardRequests/req-1`).set({
      rewardId: 'r',
      memberId: 'm-mia',
      requestedBy: 'm-mia',
      requestedAt: new Date(),
      status: 'waiting',
      cost: 5,
    });
    const items = await eventually(inboxOf('chores'), (found) => found.length === 2);
    expect(items[0]?.['detail']).toBe('Mia asked for a reward');
  });
});

describe('sendTestNotification', () => {
  it('reaches only its caller, and says there is no phone to reach', async () => {
    const { sam, householdId } = await householdOfTwo();
    const result = await callAs<{ outcome: string }>(sam, 'sendTestNotification', { householdId });
    expect(result.outcome).toBe('noDevice');
    const items = await adminDb().collection(`households/${householdId}/notificationInbox`).get();
    expect(items.docs).toHaveLength(1);
    expect(items.docs[0]?.get('category')).toBe('test');
    const again = await callAs<{ outcome: string }>(sam, 'sendTestNotification', { householdId });
    expect(['alreadySent', 'noDevice']).toContain(again.outcome);
  });

  it('refuses somebody who is not in the household, and nobody at all', async () => {
    const { householdId } = await householdOfTwo();
    const stranger = await signUp();
    await expectRefusal(callAs(stranger, 'sendTestNotification', { householdId }), 'notAMember');
    await expectRefusal(callAs(null, 'sendTestNotification', { householdId }), 'notSignedIn');
    await expectRefusal(callAs(stranger, 'sendTestNotification', {}), 'badRequest');
  });
});
