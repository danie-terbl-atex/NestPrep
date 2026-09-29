import { Timestamp } from 'firebase-admin/firestore';
import { describe, expect, it } from 'vitest';

import {
  storedHouseholdCohort,
  storedHouseholdWeek,
} from '../../src/product_analytics/analytics_documents';
import { premiumConversionInput } from '../../src/product_analytics/conversion_ledger';
import { recordActivityInput } from '../../src/product_analytics/record_activity';
import { summariseWeek } from '../../src/product_analytics/weekly_summary';
import { ALLOWED_FIELDS, FORBIDDEN_FIELD_WORDS } from '../product_analytics_fields';

/**
 * No event or aggregate carries a name, an email, a child's detail, a document
 * or a lunch (phase 1 definition of done, `ENG-22`, POPIA).
 *
 * The emulator suite checks the documents really written; this checks the
 * shapes that decide them, without anything running.
 */
describe('what the beta numbers are allowed to hold', () => {
  it('names no field after a person or a child"s details', () => {
    for (const [collection, fields] of Object.entries(ALLOWED_FIELDS)) {
      for (const field of fields) {
        const leaks = FORBIDDEN_FIELD_WORDS.filter((word) =>
          field.toLowerCase().includes(word.toLowerCase()),
        );
        expect(leaks, `${collection}.${field}`).toEqual([]);
      }
    }
  });

  it('the weekly totals hold exactly the allowed counts and nothing else', () => {
    const numbers = summariseWeek({
      week: '2026-W40',
      householdWeeks: [
        { householdId: 'h1', week: '2026-W40', activeMemberIds: ['m1', 'm2'], lunchPlanIds: [] },
      ],
      cohort: [],
      conversions: [],
      isInviteCohortComplete: false,
    });
    const allowed = ALLOWED_FIELDS['analyticsWeeks'] ?? [];
    // `computedAt` is the server's timestamp, added by the rollup as it writes.
    expect(Object.keys(numbers).sort()).toEqual(
      allowed.filter((field) => field !== 'computedAt').sort(),
    );
  });

  it('the weekly totals carry no identifier at all — not even an opaque one', () => {
    const allowed = ALLOWED_FIELDS['analyticsWeeks'] ?? [];
    expect(allowed.filter((field) => /id$|ids$/i.test(field))).toEqual([]);
  });

  it('the ledgers are read back with no field beyond the allowed ones', () => {
    const week = storedHouseholdWeek.parse({
      householdId: 'h1',
      week: '2026-W40',
      activeMemberIds: ['m1'],
      householdName: 'The Parkers',
    });
    expect(
      Object.keys(week).every((key) => ALLOWED_FIELDS['analyticsHouseholdWeeks']?.includes(key)),
    ).toBe(true);

    const cohort = storedHouseholdCohort.parse({
      householdId: 'h1',
      cohortWeek: '2026-W40',
      createdAt: Timestamp.fromDate(new Date('2026-09-28T08:00:00Z')),
      adminEmail: 'sam@example.com',
    });
    expect(
      Object.keys(cohort).every((key) => ALLOWED_FIELDS['analyticsHouseholds']?.includes(key)),
    ).toBe(true);
  });
});

describe('what a client can send', () => {
  it('recordActivity takes a household and drops anything else it is handed', () => {
    const parsed = recordActivityInput.parse({
      householdId: 'h1',
      memberId: 'somebody-else',
      displayName: 'Sam',
    });
    expect(parsed).toEqual({ householdId: 'h1' });
  });

  it('recordActivity refuses a body with no household in it', () => {
    expect(recordActivityInput.safeParse({}).success).toBe(false);
    expect(recordActivityInput.safeParse({ householdId: '' }).success).toBe(false);
    expect(recordActivityInput.safeParse({ householdId: 'x'.repeat(65) }).success).toBe(false);
  });
});

describe('the conversion hook subscriptions will call (V2)', () => {
  const valid = {
    householdId: 'h1',
    conversionId: 'GPA.1234-5678-9012-34567',
    trigger: 'additionalChild',
    convertedAt: new Date('2026-10-01T10:00:00Z'),
  };

  it('accepts a known trigger', () => {
    expect(premiumConversionInput.safeParse(valid).success).toBe(true);
  });

  it('refuses a trigger that is free text, which is how a sentence about a child gets in', () => {
    expect(
      premiumConversionInput.safeParse({ ...valid, trigger: 'wanted Mia"s allergy plan' }).success,
    ).toBe(false);
  });

  it('refuses a conversion id that could hold anything but an id', () => {
    expect(
      premiumConversionInput.safeParse({ ...valid, conversionId: 'sam@example.com' }).success,
    ).toBe(false);
  });
});
