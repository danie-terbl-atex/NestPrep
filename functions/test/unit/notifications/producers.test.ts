import type { BatchResponse } from 'firebase-admin/messaging';
import { describe, expect, it } from 'vitest';

import {
  claimNowWaiting,
  familyDrafts,
  rewardNowWaiting,
} from '../../../src/notifications/chore_delivery';
import {
  reminderDrafts,
  reminderRecipients,
  type PendingReminder,
} from '../../../src/notifications/expiry_delivery';
import { outcomeOf } from '../../../src/notifications/fcm_push_sender';
import { testOutcome } from '../../../src/notifications/send_test_notification';
import { handoverDrafts } from '../../../src/notifications/shift_delivery';
import { CHORE_CHECK_TEXT } from '../../../src/notifications/push_text';
import { ROSTER } from './fixtures';

/**
 * What the other features ask this one to say, and to whom
 * (notifications ADR-0001): expiry reminders (documents ADR-0005), the shift
 * handover (nanny-hub ADR-0002), chores and rewards (todos ADR-0003).
 */

const householdReminder: PendingReminder = {
  scope: 'household',
  ownerMemberId: null,
  documentId: 'passport',
  documentName: 'Leo passport',
  expiresOn: '2026-10-29',
  daysBefore: 30,
  dueOn: '2026-09-29',
  status: 'pending',
};

const ids = (drafts: { memberId: string }[]): string[] => drafts.map((draft) => draft.memberId);

describe('an expiry reminder', () => {
  it('about a household document goes to everybody with the documents grant', () => {
    expect(ids(reminderRecipients(ROSTER, householdReminder))).toEqual(['m-sam', 'm-pat']);
  });

  it('about a vault document goes to its owner and the admins, as ADR-0005 asks', () => {
    const vault = { ...householdReminder, scope: 'vault' as const, ownerMemberId: 'm-pat' };
    expect(ids(reminderRecipients(ROSTER, vault))).toEqual(['m-sam', 'm-pat']);
    const kids = { ...vault, ownerMemberId: 'm-mia' };
    // A kid tablet is not the vault's person: only the admin hears.
    expect(ids(reminderRecipients(ROSTER, kids))).toEqual(['m-sam']);
  });

  it('never names the document on the lock screen, and names a vault one nowhere', () => {
    const [shared] = reminderDrafts(
      'r1',
      householdReminder,
      reminderRecipients(ROSTER, householdReminder),
    );
    expect(shared?.text.body).toBe('One of the household’s documents expires in 30 days.');
    expect(shared?.detail).toBe('Leo passport · Expires in 30 days');
    expect(shared?.id).toBe('expiry_r1_m-sam');
    const vault = { ...householdReminder, scope: 'vault' as const, ownerMemberId: 'm-sam' };
    const [own] = reminderDrafts('r2', vault, reminderRecipients(ROSTER, vault));
    expect(`${own?.text.body ?? ''} ${own?.detail ?? ''}`).not.toContain('passport');
    expect(own?.target).toEqual({ kind: 'vault', id: 'm-sam' });
  });
});

describe('a shift handover', () => {
  it('goes to the family, never to the carer or the helper', () => {
    const drafts = handoverDrafts(
      ROSTER,
      'shift-1',
      { carerMemberId: 'm-nomsa', entryCount: 6 },
      '2026-09-29',
    );
    expect(ids(drafts)).toEqual(['m-sam', 'm-pat']);
    expect(drafts[0]?.detail).toBe('From Nomsa · 6 moments');
    expect(drafts[0]?.text.body).not.toContain('Nomsa');
    expect(drafts[0]?.target).toEqual({ kind: 'shiftSummary', id: 'shift-1' });
  });
});

describe('a chore to check', () => {
  const claim = { memberId: 'm-mia', title: 'Make your bed', status: 'pending', round: 1 };

  it('is news when a claim starts waiting, or starts a new round', () => {
    expect(claimNowWaiting(undefined, claim)).toBe(1);
    expect(claimNowWaiting({ ...claim, status: 'sentBack' }, { ...claim, round: 2 })).toBe(2);
  });

  it('is not news when nothing that matters moved, or it stopped waiting', () => {
    expect(claimNowWaiting(claim, claim)).toBeNull();
    expect(claimNowWaiting(claim, { ...claim, status: 'awarded' })).toBeNull();
    expect(claimNowWaiting(undefined, { what: 'garbage' })).toBeNull();
  });

  it('goes to family only', () => {
    const drafts = familyDrafts(ROSTER, {
      idPrefix: 'chore_c1_1',
      text: CHORE_CHECK_TEXT,
      detail: 'Mia · Make your bed',
      sourceKind: 'pointClaim',
      sourceId: 'c1',
      localDate: '2026-09-29',
    });
    expect(ids(drafts)).toEqual(['m-sam', 'm-pat']);
    expect(drafts[0]?.id).toBe('chore_c1_1_m-sam');
  });
});

describe('a reward asked for', () => {
  it('is news only on the move into waiting', () => {
    const request = { memberId: 'm-mia', status: 'waiting' };
    expect(rewardNowWaiting({ memberId: 'm-mia' }, request)).toBe(true);
    expect(rewardNowWaiting(request, request)).toBe(false);
    expect(rewardNowWaiting(request, { ...request, status: 'fulfilled' })).toBe(false);
  });
});

describe('what FCM answered', () => {
  const response = (codes: (string | null)[]): BatchResponse =>
    ({
      successCount: codes.filter((code) => code === null).length,
      failureCount: codes.filter((code) => code !== null).length,
      responses: codes.map((code) =>
        code === null ? { success: true } : { success: false, error: { code } },
      ),
    }) as unknown as BatchResponse;

  it('forgets a token that belongs to no phone, and keeps the rest', () => {
    const outcome = outcomeOf(
      ['a', 'b', 'c'],
      response([
        null,
        'messaging/registration-token-not-registered',
        'messaging/invalid-registration-token',
      ]),
    );
    expect(outcome).toEqual({ delivered: 1, invalidTokens: ['b', 'c'], retryable: false });
  });

  it('an outage is worth trying again', () => {
    expect(outcomeOf(['a'], response(['messaging/server-unavailable'])).retryable).toBe(true);
  });

  it('a test says what happened', () => {
    expect(testOutcome(0, undefined)).toBe('alreadySent');
    expect(testOutcome(1, 'sent')).toBe('sent');
    expect(testOutcome(1, 'noDevice')).toBe('noDevice');
    expect(testOutcome(1, 'retry')).toBe('failed');
  });
});
