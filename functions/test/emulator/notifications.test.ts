import { Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';

import { runMorningDigest } from '../../src/notifications/morning_digest';
import { runNotificationDelivery } from '../../src/notifications/notification_delivery';
import { deliverShiftSummary } from '../../src/notifications/shift_delivery';
import { adminDb, clearFirestore } from './emulator_harness';
import {
  HALF_SIX,
  HOME,
  MIA,
  PAT,
  RecordingSender,
  SAM,
  THANDI,
  TODAY,
  ZONES,
  givenABusyTuesday,
  givenSettings,
  givenTheHousehold,
  inbox,
  inboxItem,
  pushOf,
} from './notifications_fixture';

/**
 * The morning digest and the delivery job against a real Firestore
 * (notifications ADR-0001, ADR-0002). A schedule cannot be triggered in the
 * emulator, so these run the jobs' bodies — the functions the schedules call —
 * with a fixed clock and a recording push service. What they prove is what a
 * unit test cannot: the collection-group queries find the right people, the
 * inbox is written once, and a push goes to the right phones and no others.
 */

const at = (iso: string): Date => new Date(iso);

beforeEach(async () => {
  await clearFirestore();
  await givenTheHousehold();
  await givenABusyTuesday();
});

describe('the morning digest', () => {
  it('reaches the person whose morning it is, with their day, on their phones', async () => {
    await givenSettings(SAM.member, { minute: 390 });
    await givenSettings(PAT.member, { minute: 420 });
    const sender = new RecordingSender();

    const report = await runMorningDigest({
      store: adminDb(),
      sender,
      now: HALF_SIX,
      zones: ZONES,
    });

    expect(report.created).toBe(1);
    const digest = await inboxItem(`digest_${SAM.member}_${TODAY}`);
    expect(digest?.['category']).toBe('digest');
    expect(digest?.['memberId']).toBe(SAM.member);
    const sections = digest?.['sections'] as { kind: string }[];
    expect(sections.map((section) => section.kind)).toEqual([
      'events',
      'pack',
      'chores',
      'documents',
    ]);
    expect(pushOf(digest).state).toBe('sent');

    expect(sender.sent).toHaveLength(1);
    const [push] = sender.sent;
    expect(push?.tokens).toEqual([SAM.token]);
    expect(push?.body).toBe('1 event · 2 things to pack · 1 chore · 1 document to renew');
    expect(Object.keys(push?.data ?? {}).sort()).toEqual([
      'householdId',
      'inboxId',
      'target',
      'targetId',
    ]);
    expect(JSON.stringify(push)).not.toMatch(/Mia|Cheese|passport|milk/);
  });

  it('sends nothing twice — not on the next run, and not on a run that overlaps', async () => {
    await givenSettings(SAM.member, { minute: 390 });
    const sender = new RecordingSender();
    await runMorningDigest({ store: adminDb(), sender, now: HALF_SIX, zones: ZONES });
    await runMorningDigest({
      store: adminDb(),
      sender,
      now: at('2026-09-29T04:45:00Z'),
      zones: ZONES,
    });
    await runMorningDigest({ store: adminDb(), sender, now: HALF_SIX, zones: ZONES });
    expect(sender.sent).toHaveLength(1);
    expect((await inbox()).filter((item) => item['category'] === 'digest')).toHaveLength(1);
  });

  it('a person who changed their time gets it then, and one who opted out never', async () => {
    await givenSettings(PAT.member, { minute: 420 });
    await givenSettings(SAM.member, { enabled: false });
    const sender = new RecordingSender();
    await runMorningDigest({ store: adminDb(), sender, now: HALF_SIX, zones: ZONES });
    expect(sender.sent).toHaveLength(0);
    await runMorningDigest({
      store: adminDb(),
      sender,
      now: at('2026-09-29T05:00:00Z'),
      zones: ZONES,
    });
    expect(sender.sent.map((push) => push.tokens)).toEqual([[PAT.token]]);
  });

  it('a helper who only cleans is sent nothing, however early they rise', async () => {
    await givenSettings(THANDI.member, { minute: 390 });
    const sender = new RecordingSender();
    const report = await runMorningDigest({
      store: adminDb(),
      sender,
      now: HALF_SIX,
      zones: ZONES,
    });
    expect(report.quiet).toBe(1);
    expect(sender.sent).toHaveLength(0);
    expect(await inbox()).toEqual([]);
  });

  it('a kid tablet gets its own lunch box', async () => {
    await givenSettings(MIA.member, { minute: 390 });
    const sender = new RecordingSender();
    await runMorningDigest({ store: adminDb(), sender, now: HALF_SIX, zones: ZONES });
    const digest = await inboxItem(`digest_${MIA.member}_${TODAY}`);
    const pack = (digest?.['sections'] as { kind: string; items: { text: string }[] }[]).find(
      (section) => section.kind === 'pack',
    );
    expect(pack?.items.map((item) => item.text)).toEqual(['Your lunch box', 'Swimming kit']);
    expect(sender.sent[0]?.tokens).toEqual([MIA.token]);
  });

  it('a household in another zone gets its digest at its own morning', async () => {
    const auckland = await givenTheHousehold({ id: 'h-auckland', timeZone: 'Pacific/Auckland' });
    await givenABusyTuesday(auckland);
    await givenSettings(SAM.member, { minute: 390 }, auckland);
    const sender = new RecordingSender();
    // 06:30 on Wednesday the 30th in Auckland.
    await runMorningDigest({
      store: adminDb(),
      sender,
      now: at('2026-09-29T17:30:00Z'),
      zones: ZONES,
    });
    expect(await inboxItem(`digest_${SAM.member}_2026-09-30`, auckland)).toBeDefined();
    expect(await inboxItem(`digest_${SAM.member}_2026-09-29`)).toBeUndefined();
  });

  it('inside quiet hours the inbox has it at once and the buzz waits for the morning', async () => {
    await givenSettings(SAM.member, { minute: 330, quiet: [21 * 60, 6 * 60] });
    const sender = new RecordingSender();
    await runMorningDigest({
      store: adminDb(),
      sender,
      now: at('2026-09-29T03:30:00Z'),
      zones: ZONES,
    });
    const id = `digest_${SAM.member}_${TODAY}`;
    expect(pushOf(await inboxItem(id)).state).toBe('pending');
    expect(sender.sent).toHaveLength(0);

    await runNotificationDelivery(adminDb(), sender, at('2026-09-29T03:45:00Z'));
    expect(sender.sent).toHaveLength(0);
    await runNotificationDelivery(adminDb(), sender, at('2026-09-29T04:00:00Z'));
    expect(sender.sent).toHaveLength(1);
    expect(pushOf(await inboxItem(id)).state).toBe('sent');
  });
});

describe('the push itself', () => {
  it('forgets a token FCM says belongs to no phone', async () => {
    await givenSettings(SAM.member, { minute: 390 });
    const sender = new RecordingSender(() => ({
      delivered: 0,
      invalidTokens: [SAM.token],
      retryable: false,
    }));
    await runMorningDigest({ store: adminDb(), sender, now: HALF_SIX, zones: ZONES });
    expect((await adminDb().doc(`users/${SAM.uid}/pushTokens/${SAM.token}`).get()).exists).toBe(
      false,
    );
    expect(pushOf(await inboxItem(`digest_${SAM.member}_${TODAY}`)).state).toBe('failed');
  });

  it('tries an outage again, three times in all, then leaves it to the inbox', async () => {
    await givenSettings(SAM.member, { minute: 390 });
    const sender = new RecordingSender(() => ({
      delivered: 0,
      invalidTokens: [],
      retryable: true,
    }));
    await runMorningDigest({ store: adminDb(), sender, now: HALF_SIX, zones: ZONES });
    const id = `digest_${SAM.member}_${TODAY}`;
    expect(pushOf(await inboxItem(id))).toMatchObject({ state: 'pending', attempts: 1 });
    await runNotificationDelivery(adminDb(), sender, at('2026-09-29T04:36:00Z'));
    await runNotificationDelivery(adminDb(), sender, at('2026-09-29T04:42:00Z'));
    expect(sender.sent).toHaveLength(3);
    expect(pushOf(await inboxItem(id))).toMatchObject({ state: 'failed', attempts: 3 });
    await runNotificationDelivery(adminDb(), sender, at('2026-09-29T05:00:00Z'));
    expect(sender.sent).toHaveLength(3);
  });

  it('somebody with no phone registered still has it in the inbox', async () => {
    await adminDb().doc(`users/${SAM.uid}/pushTokens/${SAM.token}`).delete();
    await givenSettings(SAM.member, { minute: 390 });
    const sender = new RecordingSender();
    await runMorningDigest({ store: adminDb(), sender, now: HALF_SIX, zones: ZONES });
    expect(pushOf(await inboxItem(`digest_${SAM.member}_${TODAY}`)).state).toBe('noDevice');
    expect(sender.sent).toHaveLength(0);
  });
});

describe('expiry reminders (documents ADR-0005)', () => {
  async function givenAReminder(id: string, expiresOn: string): Promise<void> {
    await adminDb().doc(`${HOME}/expiryReminders/${id}`).set({
      scope: 'household',
      ownerMemberId: null,
      documentId: 'passport',
      documentName: 'Mia passport',
      expiresOn,
      daysBefore: 30,
      dueOn: TODAY,
      status: 'pending',
      createdAt: new Date(),
    });
  }

  it('goes to everybody with the documents grant, once, and is marked sent', async () => {
    await givenAReminder('r1', '2026-10-11');
    const sender = new RecordingSender();
    const noon = at('2026-09-29T10:00:00Z');
    await runNotificationDelivery(adminDb(), sender, noon);
    await runNotificationDelivery(adminDb(), sender, noon);

    const items = (await inbox()).filter((item) => item['category'] === 'documents');
    expect(items.map((item) => item['memberId']).sort()).toEqual([PAT.member, SAM.member]);
    expect(sender.sent).toHaveLength(2);
    expect(sender.sent[0]?.body).toBe('One of the household’s documents expires in 30 days.');
    const reminder = (await adminDb().doc(`${HOME}/expiryReminders/r1`).get()).data();
    expect(reminder?.['status']).toBe('sent');
    expect(reminder?.['sentAt']).toBeInstanceOf(Timestamp);
  });

  it('a reminder for a date the document no longer has is stale, and skipped', async () => {
    await givenAReminder('r2', '2026-12-01');
    const sender = new RecordingSender();
    await runNotificationDelivery(adminDb(), sender, at('2026-09-29T10:00:00Z'));
    const reminder = (await adminDb().doc(`${HOME}/expiryReminders/r2`).get()).data();
    expect(reminder).toMatchObject({ status: 'skipped', skippedBecause: 'stale' });
    expect(sender.sent).toHaveLength(0);
  });
});

describe('a shift handover (nanny-hub ADR-0002)', () => {
  it('goes to the family and the summary is marked sent', async () => {
    // Created as nothing to deliver, so the deployed trigger — which would
    // reach for the real FCM — leaves it alone; then made pending, which is
    // an update and fires nothing. The trigger's own path is in
    // `notifications_triggers.test.ts`, with no phones to reach.
    const ref = adminDb().doc(`${HOME}/nannyShiftSummaries/shift-1`);
    await ref.set({ carerMemberId: 'm-nomsa', entryCount: 4, delivery: { state: 'drafting' } });
    await new Promise((resolve) => setTimeout(resolve, 1500));
    await ref.update({ delivery: { state: 'pending' } });
    const sender = new RecordingSender();
    const outcome = await deliverShiftSummary(adminDb(), sender, {
      householdId: 'h-notify',
      shiftId: 'shift-1',
      now: at('2026-09-29T16:00:00Z'),
    });
    expect(outcome).toBe('sent');
    expect(sender.sent.map((push) => push.tokens[0]).sort()).toEqual([PAT.token, SAM.token]);
    const summary = (await adminDb().doc(`${HOME}/nannyShiftSummaries/shift-1`).get()).data();
    expect((summary?.['delivery'] as { state: string }).state).toBe('sent');
  });
});
