import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { todayIn } from '../documents/expiry_schedule';
import { refuse } from '../household/errors';
import { parseInput, requireUid } from '../household/parse_input';
import { db } from '../shared/firestore';
import { loadRoster } from './household_roster';
import { deliverDrafts } from './inbox_delivery';
import { pushService } from './push_service';
import { TEST_TEXT } from './push_text';
import { sendTestNotificationInput } from './schemas';

/**
 * "Send me a test" from the notification settings (notifications ADR-0003):
 * one push to every phone the caller is signed in on, through exactly the
 * path every other notification takes — so a person can see the channel
 * works, and so can we, on a real phone.
 *
 * Only to the caller, never to anybody else; at most one a minute, because
 * its id is the person and the minute (BE-06). The answer says what happened
 * so the screen can say it in words: sent, no phone registered, or not
 * delivered.
 */
export type TestOutcome = 'sent' | 'noDevice' | 'failed' | 'alreadySent';

export const sendTestNotification = onCall(async (request) => {
  const uid = requireUid(request.auth);
  const input = parseInput(sendTestNotificationInput, request.data);
  const store = db();
  const now = new Date();

  const roster = await loadRoster(store, input.householdId);
  const me = roster?.recipients.find((recipient) => recipient.uids.includes(uid));
  if (roster === null || me === undefined) {
    throw refuse('notAMember');
  }
  const minute = Math.floor(now.getTime() / 60_000);
  const report = await deliverDrafts(
    { store, sender: pushService(), householdId: input.householdId, zone: roster.zone, now },
    [
      {
        id: `test_${me.memberId}_${String(minute)}`,
        memberId: me.memberId,
        category: 'test',
        text: TEST_TEXT,
        detail: null,
        sections: [],
        target: { kind: 'inboxItem', id: null },
        source: { kind: 'test', id: String(minute) },
        localDate: todayIn(roster.zone, now),
      },
    ],
  );
  const outcome: TestOutcome = testOutcome(report.created, report.dispatched[0]);
  logger.info('test notification', { householdId: input.householdId, outcome });
  return { outcome };
});

export function testOutcome(created: number, dispatched: string | undefined): TestOutcome {
  if (created === 0) return 'alreadySent';
  if (dispatched === 'sent') return 'sent';
  if (dispatched === 'noDevice' || dispatched === 'gone') return 'noDevice';
  return 'failed';
}
