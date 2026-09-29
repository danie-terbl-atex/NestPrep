import { describe, expect, it } from 'vitest';

import {
  EXPIRED_GRACE_DAYS,
  EXPIRY_REMINDER_DAYS_BEFORE,
  addDays,
  dayNumber,
  reminderId,
  reminderStage,
  todayIn,
} from '../../src/documents/expiry_schedule';

/**
 * When an expiry date raises a reminder (documents ADR-0005). The job is only
 * as right as this: one stage at a time, the tightest one reached, and nothing
 * for a date that is not a date.
 */
describe('the reminder schedule', () => {
  it('is 90, 30 and 7 days before, and the day itself', () => {
    expect(EXPIRY_REMINDER_DAYS_BEFORE).toEqual([90, 30, 7, 0]);
  });

  it('raises nothing while the expiry is further off than the first offset', () => {
    expect(reminderStage('2027-01-01', addDays('2027-01-01', -91))).toBeUndefined();
  });

  it('raises the tightest offset reached, and only that one', () => {
    const expiry = '2027-06-30';
    expect(reminderStage(expiry, addDays(expiry, -90))).toBe(90);
    expect(reminderStage(expiry, addDays(expiry, -31))).toBe(90);
    expect(reminderStage(expiry, addDays(expiry, -30))).toBe(30);
    expect(reminderStage(expiry, addDays(expiry, -8))).toBe(30);
    expect(reminderStage(expiry, addDays(expiry, -7))).toBe(7);
    expect(reminderStage(expiry, addDays(expiry, -1))).toBe(7);
  });

  it('a document added eight days out raises one reminder, not three past-due ones', () => {
    expect(reminderStage('2027-06-30', '2027-06-22')).toBe(30);
  });

  it('on the day and for a week after it is "expired"', () => {
    const expiry = '2027-06-30';
    expect(reminderStage(expiry, expiry)).toBe(0);
    expect(reminderStage(expiry, addDays(expiry, EXPIRED_GRACE_DAYS))).toBe(0);
    expect(reminderStage(expiry, addDays(expiry, EXPIRED_GRACE_DAYS + 1))).toBeUndefined();
  });

  it('refuses a date that is not in the calendar rather than guessing one', () => {
    expect(dayNumber('2027-02-29')).toBeUndefined();
    expect(dayNumber('2028-02-29')).toBeDefined();
    expect(dayNumber('29/02/2028')).toBeUndefined();
    expect(reminderStage('2027-02-31', '2027-02-01')).toBeUndefined();
  });

  it('counts whole days across a month and a leap day', () => {
    expect(addDays('2028-02-28', 1)).toBe('2028-02-29');
    expect(addDays('2028-03-01', -1)).toBe('2028-02-29');
    expect(addDays('2027-12-31', 1)).toBe('2028-01-01');
  });
});

describe('today', () => {
  it('is the household’s day, not the server’s', () => {
    // 23:30 UTC on the 30th is already the 1st in Johannesburg (UTC+2).
    const lateEvening = new Date(Date.UTC(2027, 5, 30, 23, 30));
    expect(todayIn('UTC', lateEvening)).toBe('2027-06-30');
    expect(todayIn('Africa/Johannesburg', lateEvening)).toBe('2027-07-01');
  });

  it('falls back to UTC for a zone nobody has heard of', () => {
    const noon = new Date(Date.UTC(2027, 5, 30, 12));
    expect(todayIn('Mars/Olympus_Mons', noon)).toBe('2027-06-30');
  });
});

describe('the reminder id', () => {
  it('is the same every time, so a second sweep writes nothing new', () => {
    const key = {
      scope: 'vault' as const,
      ownerMemberId: 'm-emma',
      documentId: 'doc-1',
      expiresOn: '2027-06-30',
      daysBefore: 30,
    };
    expect(reminderId(key)).toBe(reminderId({ ...key }));
    expect(reminderId(key)).toBe('vault_m-emma_doc-1_2027-06-30_30');
  });

  it('changes with the date, so a renewed passport is reminded about afresh', () => {
    const base = {
      scope: 'household' as const,
      ownerMemberId: null,
      documentId: 'doc-1',
      daysBefore: 30,
    };
    expect(reminderId({ ...base, expiresOn: '2027-06-30' })).not.toBe(
      reminderId({ ...base, expiresOn: '2037-06-30' }),
    );
    expect(reminderId({ ...base, expiresOn: '2027-06-30' })).toContain('household_household_');
  });
});
