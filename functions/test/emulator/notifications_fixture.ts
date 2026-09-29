import { Timestamp } from 'firebase-admin/firestore';

import { ROLE_DEFAULTS, uniformGrant } from '../../src/household/access';
import type { PushMessage, PushOutcome, PushSender } from '../../src/notifications/push_sender';
import { adminDb } from './emulator_harness';

/**
 * A household for the notifications suite, written straight through the
 * Admin SDK the way the app and the other Functions leave it: two parents
 * with a phone each, a child on a kid tablet, a carer and a helper who only
 * cleans. The job bodies run against it with a recording push service, so
 * what "was sent" is a list the test reads rather than a phone.
 */

export const HOUSEHOLD_ID = 'h-notify';
export const HOME = `households/${HOUSEHOLD_ID}`;

export const SAM = { uid: 'uid-sam', member: 'm-sam', token: 'token-sam' };
export const PAT = { uid: 'uid-pat', member: 'm-pat', token: 'token-pat' };
export const MIA = { uid: 'kid-tablet', member: 'm-mia', token: 'token-tablet' };
export const NOMSA = { uid: 'uid-nomsa', member: 'm-nomsa' };
export const THANDI = { uid: 'uid-thandi', member: 'm-thandi' };

/** Tuesday 29 September 2026, 06:30 in Johannesburg. */
export const HALF_SIX = new Date('2026-09-29T04:30:00Z');
export const TODAY = '2026-09-29';
export const ZONES = ['Africa/Johannesburg', 'UTC', 'Pacific/Auckland'];

export class RecordingSender implements PushSender {
  readonly sent: PushMessage[] = [];

  constructor(private readonly answer: (message: PushMessage) => PushOutcome = everyPhone) {}

  send(message: PushMessage): Promise<PushOutcome> {
    this.sent.push(message);
    return Promise.resolve(this.answer(message));
  }
}

export function everyPhone(message: PushMessage): PushOutcome {
  return { delivered: message.tokens.length, invalidTokens: [], retryable: false };
}

export async function givenTheHousehold(
  options: { timeZone?: string; id?: string; withPhones?: boolean } = {},
): Promise<string> {
  const id = options.id ?? HOUSEHOLD_ID;
  const home = adminDb().doc(`households/${id}`);
  const cleaningOnly = { ...uniformGrant('none'), homeCare: 'own' };
  await home.set({
    name: 'The Parkers',
    timeZone: options.timeZone ?? 'Africa/Johannesburg',
    members: {
      [SAM.uid]: 'admin',
      [PAT.uid]: 'parent',
      [NOMSA.uid]: 'carer',
      [THANDI.uid]: 'helper',
    },
    profiles: {
      [SAM.uid]: SAM.member,
      [PAT.uid]: PAT.member,
      [NOMSA.uid]: NOMSA.member,
      [THANDI.uid]: THANDI.member,
    },
    access: { [NOMSA.uid]: ROLE_DEFAULTS.carer, [THANDI.uid]: cleaningOnly },
    kids: { [MIA.uid]: MIA.member },
  });
  const member = (
    displayName: string,
    role: string,
    claimedBy: string | null,
    access?: unknown,
  ): Record<string, unknown> => ({
    displayName,
    color: 'violet',
    role,
    claimedBy,
    ...(access === undefined ? {} : { access }),
  });
  await home
    .collection('members')
    .doc(SAM.member)
    .set(member('Sam', 'admin', SAM.uid));
  await home
    .collection('members')
    .doc(PAT.member)
    .set(member('Pat', 'parent', PAT.uid));
  await home
    .collection('members')
    .doc(MIA.member)
    .set(member('Mia', 'kid', null, ROLE_DEFAULTS.kid));
  await home
    .collection('members')
    .doc(NOMSA.member)
    .set(member('Nomsa', 'carer', NOMSA.uid, ROLE_DEFAULTS.carer));
  await home
    .collection('members')
    .doc(THANDI.member)
    .set(member('Thandi', 'helper', THANDI.uid, cleaningOnly));
  if (options.withPhones !== false) {
    for (const person of [SAM, PAT, MIA]) {
      await adminDb()
        .doc(`users/${person.uid}/pushTokens/${person.token}`)
        .set({ token: person.token, platform: 'android', updatedAt: new Date() });
    }
  }
  return id;
}

export async function givenSettings(
  memberId: string,
  choice: { minute?: number; enabled?: boolean; quiet?: [number, number] | null },
  householdId = HOUSEHOLD_ID,
): Promise<void> {
  const minute = choice.minute ?? 390;
  const enabled = choice.enabled ?? true;
  await adminDb()
    .doc(`households/${householdId}/notificationSettings/${memberId}`)
    .set({
      digest: { enabled, minute },
      digestSlot: enabled ? minute / 15 : null,
      categories: { documents: true, handover: true, chores: true },
      quietHours:
        choice.quiet === null || choice.quiet === undefined
          ? { enabled: false, startMinute: 1260, endMinute: 360 }
          : { enabled: true, startMinute: choice.quiet[0], endMinute: choice.quiet[1] },
      updatedBy: memberId,
      updatedAt: new Date(),
    });
}

/** Something in the day for every section a parent reads. */
export async function givenABusyTuesday(householdId = HOUSEHOLD_ID): Promise<void> {
  const home = adminDb().doc(`households/${householdId}`);
  await home
    .collection('events')
    .doc('swim')
    .set({
      title: 'Swimming lesson',
      note: null,
      date: '2026-09-01',
      startMinute: 900,
      endMinute: 960,
      recurrence: { frequency: 'weekly', interval: 1, weekdays: [2], until: null },
      memberIds: [MIA.member],
      createdBy: SAM.member,
      createdAt: new Date(),
    });
  await home
    .collection('lunchPlans')
    .doc(`${MIA.member}_2026-W40`)
    .set({
      childId: MIA.member,
      week: '2026-W40',
      weekStart: '2026-09-28',
      slots: {
        '2_main': { itemId: 'i1', name: 'Cheese sandwich', allergens: ['milk', 'gluten'] },
        '2_fruit': { itemId: 'i2', name: 'Apple', allergens: [] },
      },
      feedback: {},
    });
  await home
    .collection('tasks')
    .doc('bins')
    .set({
      title: 'Bins out',
      note: null,
      dueDate: TODAY,
      recurrence: null,
      assigneeIds: [SAM.member],
      createdBy: SAM.member,
      routineId: null,
      points: 0,
      needsApproval: false,
    });
  await home.collection('documents').doc('passport').set({
    folderId: 'f',
    name: 'Mia passport',
    contentType: 'application/pdf',
    expiresOn: '2026-10-11',
  });
}

export async function inbox(householdId = HOUSEHOLD_ID): Promise<Record<string, unknown>[]> {
  const found = await adminDb().collection(`households/${householdId}/notificationInbox`).get();
  return found.docs.map((item) => ({ id: item.id, ...item.data() }));
}

export async function inboxItem(
  id: string,
  householdId = HOUSEHOLD_ID,
): Promise<Record<string, unknown> | undefined> {
  return (await adminDb().doc(`households/${householdId}/notificationInbox/${id}`).get()).data();
}

export interface PushRecord {
  state?: string;
  attempts?: number;
  sendAfter?: Timestamp;
}

export function pushOf(item: Record<string, unknown> | undefined): PushRecord {
  const push: unknown = item?.['push'];
  return typeof push === 'object' && push !== null ? push : {};
}
