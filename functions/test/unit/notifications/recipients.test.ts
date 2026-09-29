import { describe, expect, it } from 'vitest';

import { ROLE_DEFAULTS } from '../../../src/household/access';
import { canSee, recipientOf, recipientsOf } from '../../../src/notifications/recipients';
import { HOUSEHOLD, MEMBERS, RECIPIENTS, person } from './fixtures';

/**
 * Who can be told something, and what each may see — the same levels the
 * rules read (household ADR-0003, accounts ADR-0004).
 */

describe('who is a recipient', () => {
  it('every profile somebody is signed in as, and nobody else', () => {
    expect(RECIPIENTS.map((recipient) => recipient.memberId)).toEqual([
      'm-sam',
      'm-pat',
      'm-mia',
      'm-nomsa',
      'm-thandi',
    ]);
  });

  it('a kid profile reaches its tablet', () => {
    expect(person('m-mia').uids).toEqual(['kid-tablet']);
    expect(person('m-mia').hasAccount).toBe(false);
  });

  it('somebody who has left — claimed, but no longer in the household — is nobody', () => {
    const left = { ...HOUSEHOLD, members: { 'uid-sam': 'admin' } };
    expect(recipientsOf(left, MEMBERS).map((recipient) => recipient.memberId)).toEqual([
      'm-sam',
      'm-mia',
    ]);
  });
});

describe('what each may see', () => {
  it('family sees every area', () => {
    expect(person('m-pat').isFamily).toBe(true);
    expect(canSee(person('m-pat'), 'documents')).toBe(true);
  });

  it('a helper sees only what the parent granted', () => {
    const thandi = person('m-thandi');
    expect(thandi.isFamily).toBe(false);
    expect(canSee(thandi, 'calendar')).toBe(false);
    expect(thandi.levels.homeCare).toBe('own');
  });

  it('a kid tablet holds its kid profile’s grant', () => {
    expect(person('m-mia').levels).toEqual(ROLE_DEFAULTS.kid);
  });

  it('a kid tablet whose profile is no longer a kid holds nothing', () => {
    const grownUp = { ...MEMBERS[2], id: 'm-mia', role: 'parent' as const };
    const recipient = recipientOf(HOUSEHOLD, {
      ...grownUp,
      displayName: 'Mia',
      claimedBy: null,
      access: ROLE_DEFAULTS.kid,
    });
    expect(recipient?.levels.calendar).toBe('none');
    expect(recipient?.levels.lunch).toBe('none');
  });
});
