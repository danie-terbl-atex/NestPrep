import { Timestamp } from 'firebase-admin/firestore';
import { afterAll, beforeEach, describe, expect, it } from 'vitest';

import { recordPremiumConversion } from '../../src/product_analytics/conversion_ledger';
import { LAUNCH_TIME_ZONE, weekKeyOf } from '../../src/product_analytics/iso_week';
import { rollupWeek } from '../../src/product_analytics/weekly_rollup';
import { ALLOWED_FIELDS } from '../product_analytics_fields';
import { adminDb, callAs, clearFirestore, closeAdmin, signUp } from './emulator_harness';
import {
  ADMIN_NAME,
  CHILD_NAME,
  HOUSEHOLD_NAME,
  PARTNER_NAME,
  createHousehold,
  eventually,
  joinAs,
  ledger,
  thisWeek,
} from './product_analytics_fixture';

/**
 * The beta numbers counted (product-analytics ADR-0001): the rollup against a
 * hand count, run twice, and every document a real week of use leaves behind
 * checked for anything that names a person.
 */

afterAll(closeAdmin);

describe('the rollup, against a hand count', () => {
  beforeEach(clearFirestore);

  it('counts the three numbers for a seeded week exactly as counted by hand', async () => {
    const store = adminDb();
    const week = '2026-W40';
    const monday = new Date('2026-09-28T08:00:00Z');
    const day = 24 * 60 * 60 * 1000;
    const seed = store.batch();
    const householdWeek = (id: string, members: string[], plans: string[]): void => {
      seed.set(store.doc(`analyticsHouseholdWeeks/${week}_${id}`), {
        householdId: id,
        week,
        activeMemberIds: members,
        lunchPlanIds: plans,
      });
    };
    householdWeek('h-alone', ['m1'], []); // one member: not active
    householdWeek('h-pair', ['m2', 'm3'], ['p1', 'p2']); // active, two plans
    householdWeek('h-trio', ['m4', 'm5', 'm6'], ['p3']); // active, one plan
    const cohort = (id: string, invitedAfterDays: number | null): void => {
      seed.set(store.doc(`analyticsHouseholds/${id}`), {
        householdId: id,
        cohortWeek: week,
        createdAt: Timestamp.fromDate(monday),
        firstAdultInviteAt:
          invitedAfterDays === null
            ? null
            : Timestamp.fromMillis(monday.getTime() + invitedAfterDays * day),
        firstAdultInviteRole: invitedAfterDays === null ? null : 'member',
      });
    };
    cohort('h-alone', null); // never invited
    cohort('h-pair', 2); // day 3: counts
    cohort('h-trio', 8); // day 8: does not
    await seed.commit();

    await rollupWeek(store, week, new Date('2026-10-20T00:00:00Z'));

    const totals = await ledger(`analyticsWeeks/${week}`);
    expect(totals).toMatchObject({
      week,
      weekStart: '2026-09-28',
      activeFamilies: 2,
      familiesSeen: 3,
      lunchPlansCreated: 3,
      familiesPlanningLunches: 2,
      newFamilies: 3,
      newFamiliesInvitingAnAdult: 1,
      isInviteCohortComplete: true,
    });
    expect(totals?.['computedAt']).toBeInstanceOf(Timestamp);
  });

  it('gives the same totals when it runs twice', async () => {
    const store = adminDb();
    await store.doc('analyticsHouseholdWeeks/2026-W40_h1').set({
      householdId: 'h1',
      week: '2026-W40',
      activeMemberIds: ['m1', 'm2'],
      lunchPlanIds: ['p1'],
    });
    const now = new Date('2026-10-01T00:00:00Z');
    const first = await rollupWeek(store, '2026-W40', now);
    const second = await rollupWeek(store, '2026-W40', now);
    expect(second).toEqual(first);
    expect(first.activeFamilies).toBe(1);
  });

  it('counts a premium conversion once, however often subscriptions reports it', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const convertedAt = new Date();
    const conversion = {
      householdId,
      conversionId: 'GPA.3300-1111-2222-33333',
      trigger: 'additionalChild' as const,
      convertedAt,
    };

    expect(await recordPremiumConversion(adminDb(), conversion)).toBe(true);
    expect(await recordPremiumConversion(adminDb(), conversion)).toBe(false);

    const week = weekKeyOf(convertedAt, LAUNCH_TIME_ZONE);
    const numbers = await rollupWeek(adminDb(), week, convertedAt);
    expect(numbers.premiumConversions).toBe(1);
    expect(numbers.premiumConversionsByTrigger.additionalChild).toBe(1);
  });
});

describe('what the beta numbers hold after a real week of use', () => {
  beforeEach(clearFirestore);

  it('names nobody: no field outside the allow-list, and no name, email or invite code anywhere', async () => {
    const sam = await signUp();
    const { householdId } = await createHousehold(sam);
    const alex = await joinAs(sam, householdId);
    await callAs(sam, 'recordActivity', { householdId });
    await callAs(alex.user, 'recordActivity', { householdId });
    await adminDb()
      .collection('households')
      .doc(householdId)
      .collection('lunchPlans')
      .doc('plan-1')
      .set({ child: CHILD_NAME, allergies: ['peanuts'], monday: 'peanut-free wrap' });
    await recordPremiumConversion(adminDb(), {
      householdId,
      conversionId: 'GPA.9999-0000',
      trigger: 'lunchLearning',
      convertedAt: new Date(),
    });
    await eventually(
      () => ledger(`analyticsHouseholdWeeks/${thisWeek()}_${householdId}`),
      (entry) => ((entry?.['lunchPlanIds'] as unknown[] | undefined) ?? []).length === 1,
    );
    await rollupWeek(adminDb(), thisWeek(), new Date());

    const forbidden = [
      HOUSEHOLD_NAME,
      ADMIN_NAME,
      PARTNER_NAME,
      CHILD_NAME,
      sam.email,
      alex.user.email,
      sam.uid,
      alex.user.uid,
      alex.code,
      'peanut',
      'GPA.9999-0000',
    ];
    let checked = 0;
    for (const [name, allowed] of Object.entries(ALLOWED_FIELDS)) {
      const snapshot = await adminDb().collection(name).get();
      for (const document of snapshot.docs) {
        checked += 1;
        const data = document.data();
        expect(
          Object.keys(data).filter((key) => !allowed.includes(key)),
          document.ref.path,
        ).toEqual([]);
        const written = `${document.id} ${JSON.stringify(data)}`;
        for (const value of forbidden) {
          expect(written.includes(value), `${document.ref.path} holds ${value}`).toBe(false);
        }
      }
    }
    // One of each: the household-week, the cohort, the conversion, the totals.
    expect(checked).toBeGreaterThanOrEqual(4);
  });
});
